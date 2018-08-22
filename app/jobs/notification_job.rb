# frozen_string_literal: true

# Send events of the query asynchronously
class NotificationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform query_id, url
    query = Query.find_by query_id: query_id
    query.finished? { Subscription.add_for query, url }
    error = Notification.send url,
                              events: DbConnection.using { Event.occurred_for query }
    logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}" if error
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
  end
end
