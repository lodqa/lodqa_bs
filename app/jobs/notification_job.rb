# frozen_string_literal: true

# Send events of the query asynchronously
class NotificationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform query_id, url
    Subscription.add query_id, url
    return if Notification.send url,
                                events: DbConnection.using { Event.occurred(query_id) }
    logger.error "Request to callback url is failed. URL: #{url}, message: #{res.message}"
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
  end
end
