# frozen_string_literal: true

# Utility class to send HTTP requests.
module ImmediatelyCall
  def self.back data, url
    error = HTTP.post url, data
    return unless error
    Rails.logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}"
  end
end
