# frozen_string_literal: true

# Send events of the search asynchronously
# This is for performance. Sending events may be executed for more than 5 seconds.
class SubscribeJob < ApplicationJob
  rescue_from StandardError do |exception|
    logger.fatal exception
  end

  def perform search, url
    search.subscribe url
  end
end
