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
    finish_time = LoqdaSearcher.perform query,
                                        on_start(query, start_search_callback_url, start_time),
                                        on_event(query)
    post_callback finish_search_callback_url,
                  event: 'finish_search',
                  query: query.statement,
                  start_at: start_time,
                  finish_at: finish_time,
                  elapsed_time: finish_time - start_time,
                  answers: Event.answers(job_id)
  end

  def on_event query
    ng_urls = []
    lambda do |event, data|
      event_data = save_event query, event, data
      Subscription.publish query, event_data, ng_urls
    end
  end

  def save_event query, event, data
    DbConnection.using do
      Event
        .create(
          query: query,
          event: event,
          data: { event: event }.merge(data)
        )
        .data
    end
  end

  def on_start query, start_search_callback_url, start_time
    lambda do
      post_callback start_search_callback_url,
                    event: 'start_search',
                    query: query.statement,
                    start_at: start_time,
                    message: "Searching the query #{job_id} have been starting."
      Subscription.remove query.query_id
    end
  end

  def post_callback callback_url, data
    return if Notification.send callback_url, data
    logger.error "Request to callback url is failed. URL: #{callback_url}, message: #{res.message}"
  end
end
