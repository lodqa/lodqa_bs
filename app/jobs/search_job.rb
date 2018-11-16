# frozen_string_literal: true

# A job to search query
class SearchJob < ApplicationJob
  def perform search_id
    search = DbConnection.using { Search.start! search_id }
    run search
    clean_up search
  rescue StandardError => error
    logger.error message: 'Execution of SearchJob failed.',
                 error: { message: error.message,
                          class: error.class.to_s,
                          trace: error.backtrace }

    search&.abort!
  ensure
    dispose_notifications_for search_id
  end

  private

  def run search
    Lodqa::Search.start search,
                        on_start(search),
                        on_event(search),
                        logger
  end

  # Return a proc to be called when the search will starts.
  def on_start search
    lambda do
      LateCallbacks.publish_for search,
                                DbConnection.using { search.data_for_start_event }
    end
  end

  # Return a proc to be called when events of the search will occur.
  def on_event search
    lambda do |event_type, data|
      event = save_event! search, event_type, data
      SubscriptionContainer.publish_for search, event.data
    end
  end

  def save_event! search, event_type, data
    DbConnection.using do
      Event.create search: search,
                   event: event_type,
                   data: { event: event_type }.merge(data)
    end
  end

  def clean_up search
    DbConnection.using { search.finish! }
    LateCallbacks.publish_for search,
                              DbConnection.using { search.dafa_for_finish_event }
  end

  def dispose_notifications_for search_id
    SubscriptionContainer.remove_all_for search_id
    LateCallbacks.remove_all_for search_id
  end
end
