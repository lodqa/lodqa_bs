# frozen_string_literal: true

# A job to search query
class SearchJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    Search.abort! job_id
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
      CallbackContainer.publish_for search,
                                    search.data_for_start_event
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
      Event.create search: search,
                   event: event,
                   data: { event: event }.merge(data)
    end
  end

  def clean_up search
    search = DbConnection.using { search.finish! { SubscriptionContainer.remove_all_for search } }
    CallbackContainer.publish_for search,
                                  search.dafa_for_finish_event
  end
end
