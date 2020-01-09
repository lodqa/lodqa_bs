# frozen_string_literal: true

# A job to search query
class SearchJob < ApplicationJob
  workers 4

  def perform search_id
    search = DbConnection.using { Search.start! search_id }
    run search
    clean_up search
  rescue StandardError => e
    logger.error message: 'Execution of SearchJob failed.',
                 error: { message: e.message,
                          class: e.class.to_s,
                          trace: e.backtrace }

    search&.abort!
  ensure
    dispose_notifications_for search_id
  end

  private

  def run search
    Lodqa::Search.start search.pseudo_graph_pattern,
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

      save_term_mapping! search, data
    end
  end

  def save_event! search, event_type, data
    DbConnection.using do
      Event.create pseudo_graph_pattern: search.pseudo_graph_pattern,
                   event: event_type,
                   data: { event: event_type }.merge(data)
    end
  end

  def save_term_mapping! search, data
    dataset_name = data[:dataset].present? ? data[:dataset][:name] : ''
    mapping = data[:mappings].present? ? data[:mappings][:genes] : ''

    DbConnection.using do
      TermMapping.create pseudo_graph_pattern: search.pseudo_graph_pattern,
                         dataset_name: dataset_name,
                         mapping: mapping
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
