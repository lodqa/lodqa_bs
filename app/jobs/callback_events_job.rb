# frozen_string_literal: true

# Send a search event asynchronously. This is for performance.
# Because the time it takes to send an event depends on the performance of the receiving server.
class CallbackEventsJob < ApplicationJob
  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform search, url
    call_back_events_about search, url
  end

  private

  # Call back events about an exiting search.
  def call_back_events_about search, callback_url
    case search.pseudo_graph_pattern.state
    # when :aborted Aborted seraches do not match new queries.
    when :queued
      # Callbacks will be called after the job start.
      LateCallbacks.add_for search, callback_url
    when :running
      JsonResource.append_all callback_url,
                              DbConnection.using { search.data_for_start_event }
      LateCallbacks.add_for search, callback_url
    when :finished
      JsonResource.append_all callback_url,
                              DbConnection.using { search.data_for_start_event },
                              DbConnection.using { search.dafa_for_finish_event }
    end
  end
end
