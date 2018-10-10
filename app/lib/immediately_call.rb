# frozen_string_literal: true

# Utility class to send HTTP requests.
module ImmediatelyCall
  def self.back url, *data
    HTTP.start(url) do |http_conn|
      data.each do |datum|
        error = http_conn.post datum
        next unless error
        Rails.logger.error "Request to callback url is failed. URL: #{url}, error_message: #{error}"
      end
    end
  end
end
