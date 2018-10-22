# frozen_string_literal: true

# Subscribe search
module Subscribable
  TRANSMIT_DATA_SIZE_UPPER_LIMIT = 500_000
  extend ActiveSupport::Concern

  def subscribe url
    subsribe_serach_if_running self, url
    notify_existing_events_to url, self
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
  end

  private

  # There is no trigger to delete subscription of finished search.
  def subsribe_serach_if_running search, url
    search.not_finished? { SubscriptionContainer.add_for search, url }
  end

  def notify_existing_events_to url, search
    events = DbConnection.using { Event.occurred_for search }
    JSONResource.append_all url, *(split(events).map { |e| { events: e } })
  end

  # Divide the event array into a size approximate to the transmission data size upper limit.
  def split events
    return events unless events.any?

    total_size = events.to_json.length
    return [events] if total_size <= TRANSMIT_DATA_SIZE_UPPER_LIMIT

    # One transmission data size is calculated by the number of events.
    # Please note that if an event is huge, the send data size limit may be exceeded.
    number_of_chunk = total_size.fdiv(TRANSMIT_DATA_SIZE_UPPER_LIMIT).ceil
    chunk_size = events.length / number_of_chunk
    events.each_slice(chunk_size).to_a
  end
end
