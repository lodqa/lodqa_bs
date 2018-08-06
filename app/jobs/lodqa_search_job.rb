# frozen_string_literal: true

require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

# Parse query to generate SPARQLs and search all SPARQLs
class LodqaSearchJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    logger.fatal exception
  end

  def perform query, start_search_callback_url, finish_search_callback_url
    query_id = job_id
    start_time = Time.now
    finish_time = execute query_id, query, start_time do
      post_callback start_search_callback_url,
                    event: 'start_search',
                    query: query,
                    start_at: start_time,
                    message: "Searching the query #{query_id} have been starting."
    end
    post_callback finish_search_callback_url,
                  event: 'finish_search',
                  query: query,
                  start_at: start_time,
                  finish_at: finish_time,
                  elapsed_time: finish_time - start_time,
                  answers: Answer.select(:uri, :label)
                    .where(query_id: query_id)
                                 .as_json(except: :id)
  end

  private

  def execute query_id, query, _start_time
    threads = execute_on_all_datasets query_id, query

    yield

    threads.each(&:join)
    Time.now
  end

  def execute_on_all_datasets query_id, query
    Lodqa::Sources.datasets.map.with_index(1) do |dataset, n|
      Thread.start do
        executor = Lodqa::OneByOneExecutor.new dataset.merge(number: n), query, debug: false

        # Bind events to save answers
        executor.on(:answer) do |_, val|
          Answer.create query_id: query_id, uri: val[:answer][:uri], label: val[:answer][:label]
        rescue ActiveRecord::RecordNotUnique
          logger.debug "Duplicated answer: query_id: #{query_id}, uri: #{val[:answer][:uri]}"
        rescue StandardError => e
          logger.error "#{e.class}, #{e.message}"
        ensure
          ActiveRecord::Base.connection_pool.checkin Answer.connection
        end

        executor.perform
      end
    end
  end

  def post_callback callback_url, data
    uri = URI callback_url
    http = Net::HTTP.new uri.hostname, uri.port
    http.use_ssl = uri.instance_of? URI::HTTPS
    # http.set_debug_output $stderr
    req = Net::HTTP::Post.new uri.path, 'Content-Type' => 'application/json'
    req.body = data.to_json
    res = http.request req

    logger.error "Request to callback url is failed. URL: #{callback_url}, message: #{res.message}" unless res.is_a? Net::HTTPSuccess
  end
end
