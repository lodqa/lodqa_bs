# frozen_string_literal: true

# A job to search query
class SearchJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform start_search_callback_url, finish_search_callback_url
    query = DbConnection.using { Query.start! job_id }
    run_and_clean_up start_search_callback_url,
                     finish_search_callback_url,
                     query
  end

  private

  def run_and_clean_up start_search_callback_url, finish_search_callback_url, query
    Search.start query,
                 on_start(query, start_search_callback_url),
                 on_event(query)

    clean_up query, finish_search_callback_url
  end

  # Return a proc to be called when the search will starts.
  def on_start query, start_search_callback_url
    lambda do
      post_callback start_search_callback_url,
                    event: 'start_search',
                    query: query.statement,
                    start_at: query.started_at,
                    message: "Searching the query #{job_id} have been starting."
    end
  end

  # Return a proc to be called when events of the search will occur.
  def on_event query
    lambda do |event, data|
      event = save_event! query, event, data
      Subscription.publish event.data, query
    end
  end

  def save_event! query, event, data
    DbConnection.using do
      Event .create query: query,
                    event: event,
                    data: { event: event }.merge(data)
    end
  end

  def clean_up query, finish_search_callback_url
    query = DbConnection.using { query.finish! { Subscription.remove_all_for query } }
    post_callback finish_search_callback_url,
                  event: 'finish_search',
                  query: query.statement,
                  start_at: query.started_at,
                  finish_at: query.finished_at,
                  elapsed_time: query.elapsed_time,
                  answers: query.answers.as_json
  end

  def post_callback callback_url, data
    error = Notification.send callback_url, data
    return unless error
    logger.error "Request to callback url is failed. URL: #{callback_url}, error_message: #{error}"
  end
end
