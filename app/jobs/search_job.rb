# frozen_string_literal: true

# A job to search query
class SearchJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform
    search = DbConnection.using { Search.start! job_id }
    run_and_clean_up search
  end

  private

  def run_and_clean_up search
    Lodqa::Search.start search,
                        on_start(search),
                        on_event(search)

    clean_up search
  end

  # Return a proc to be called when the search will starts.
  def on_start search
    lambda do
      post_callback search.start_search_callback_url,
                    event: :start,
                    query: search.query,
                    search_id: search.search_id,
                    start_at: search.started_at
    end
  end

  # Return a proc to be called when events of the search will occur.
  def on_event search
    lambda do |event, data|
      event = save_event! search, event, data
      SubscriptionContainer.publish_for search, event.data
    end
  end

  def save_event! search, event, data
    DbConnection.using do
      Event .create search: search,
                    event: event,
                    data: { event: event }.merge(data)
    end
  end

  def clean_up search
    search = DbConnection.using { search.finish! { SubscriptionContainer.remove_all_for search } }
    post_callback search.finish_search_callback_url,
                  event: :finish,
                  query: search.query,
                  search_id: search.search_id,
                  start_at: search.started_at,
                  finish_at: search.finished_at,
                  elapsed_time: search.elapsed_time,
                  answers: search.answers.as_json
  end

  def post_callback callback_url, data
    error = HTTP.post callback_url, data
    return unless error
    logger.error "Request to callback url is failed. URL: #{callback_url}, error_message: #{error}"
  end
end
