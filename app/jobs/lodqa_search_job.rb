# frozen_string_literal: true

require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

# Parse query to generate SPARQLs and search all SPARQLs
class LodqaSearchJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform start_search_callback_url, finish_search_callback_url
    start_time = Time.now
    query = dispose_db_connection { Query.find_by query_id: job_id }
    finish_time = execute query do
      post_callback start_search_callback_url,
                    event: 'start_search',
                    query: query.statement,
                    start_at: start_time,
                    message: "Searching the query #{job_id} have been starting."
    end
    post_callback finish_search_callback_url,
                  event: 'finish_search',
                  query: query.statement,
                  start_at: start_time,
                  finish_at: finish_time,
                  elapsed_time: finish_time - start_time,
                  answers: Event.answers(job_id)
  end

  private

  EVENTS_TO_SAVE = %i[
    datasets
    pgp
    mappings
    sparql
    query_sparql
    solutions
    answer
    gateway_error
  ].freeze

  def execute query
    threads = execute_on_all_datasets query

    yield

    threads.each(&:join)
    Time.now
  end

  def execute_on_all_datasets query
    Lodqa::Sources.datasets.map.with_index 1 do |dataset, number|
      Thread.start { execute_on_a_dataset query, dataset, number }
    end
  end

  def execute_on_a_dataset query, dataset, number
    executor = Lodqa::OneByOneExecutor.new dataset.merge(number: number),
                                           query.statement,
                                           debug: false
    # Bind events to save events
    executor.on(*EVENTS_TO_SAVE) do |event, data|
      dispose_db_connection do
        Event.create query: query,
                     event: event,
                     data: { event: event }.merge(data)
      end
    end

    executor.perform
  end

  # Release db connection automatically after process done
  def dispose_db_connection
    yield
  rescue StandardError => e
    logger.error "#{e.class}, #{e.message}"
  ensure
    ActiveRecord::Base.connection_pool.checkin ApplicationRecord.connection
  end

  def post_callback callback_url, data
    return if Notification.send callback_url, data
    logger.error "Request to callback url is failed. URL: #{callback_url}, message: #{res.message}"
  end
end
