# frozen_string_literal: true

# Subscribe search
module Subscribable
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
    # pp events.count
    JSONResource.append_all url, *(split(events).map { |e| { events: e } })
  end

  def split events
    events.each_slice(100).to_a
  end
end
