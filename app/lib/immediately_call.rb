# frozen_string_literal: true

# Utility class to send HTTP requests.
module ImmediatelyCall
  def self.back data, url
    error = Channel.new(url).transmit data
    return unless error
    Rails.logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}"
  end
end
