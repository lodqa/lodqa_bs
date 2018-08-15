# frozen_string_literal: true

# Send events of the query asynchronously
class NotificationJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform url, query_id
    return if Notification.send url,
                                events: DbConnection.using { Event.occurred(query_id) }
    logger.error "Request to callback url is failed. URL: #{url}, message: #{res.message}"
  end
end
