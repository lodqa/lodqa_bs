# frozen_string_literal: true

# Send events of the search asynchronously
class NotificationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform search, url
    subsribe_serach_if_running search, url
    notify_existing_events_to url, search
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
  end

  private

  def subsribe_serach_if_running search, url
    search.not_finished? { SubscriptionContainer.add_for search, url }
  end

  def notify_existing_events_to url, search
    error = Notification.send url,
                              events: DbConnection.using { Event.occurred_for search }
    logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}" if error
  end
end
