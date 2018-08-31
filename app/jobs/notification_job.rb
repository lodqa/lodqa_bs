# frozen_string_literal: true

# Send events of the search asynchronously
class NotificationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform search_id, url
    search = Search.find_by search_id: search_id
    search.not_finished? { Subscription.add_for search, url }
    error = Notification.send url,
                              events: DbConnection.using { Event.occurred_for search }
    logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}" if error
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
  end
end
