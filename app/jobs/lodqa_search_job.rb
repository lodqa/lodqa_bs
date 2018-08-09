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
    query = DbConnection.using { Query.find_by query_id: job_id }

    perform_and_callback start_search_callback_url,
                         finish_search_callback_url,
                         start_time,
                         query
  end

  private

  def perform_and_callback start_search_callback_url, finish_search_callback_url, start_time, query
    finish_time = LoqdaSearcher.perform query do
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

  def post_callback callback_url, data
    return if Notification.send callback_url, data
    logger.error "Request to callback url is failed. URL: #{callback_url}, message: #{res.message}"
  end
end
