# frozen_string_literal: true

# Send JSON message by HTTP POST mesthod.
module JsonResource
  class << self
    def append_all url, *data
      start url do |resource|
        data.each do |datum|
          res = resource.append datum

          next unless res

          Rails.logger.error "Request to url is failed. URL: #{url}, error_message: #{res.message}"
          case res
          when Net::HTTPNotFound, Net::HTTPServerError
            # The URL is static.
            # Suspends the remaining data transmission if the received response is a server error.
            break
          when Net::HTTPClientError
            # Try to next data.
            next
          end
        end
      end
    end

    private

    def start url, &block
      JsonResource::Connection.new(url).start block
    end
  end
end
