# frozen_string_literal: true

# Utility class to send HTTP requests.
module HTTPConnection
  def self.send url, *data
    HTTP.start(url) do |http_conn|
      data.each do |datum|
        res = http_conn.post datum

        next unless res

        Rails.logger.error "Request to url is failed. URL: #{url}, error_message: #{res.message}"
        case res
        when Net::HTTPNotFound
          # The URL is static.
          break
        when Net::HTTPClientError
          # Try to next data.
          next
        when Net::HTTPServerError
          # Suspends the remaining data transmission if the received response is a server error.
          break
        end
      end
    end
  end
end
