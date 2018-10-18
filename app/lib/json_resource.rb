# frozen_string_literal: true

# Send JSON message by HTTP POST mesthod.
module JSONResource
  class << self
    def append_all url, *data
      start url do |resource|
        data.each do |datum|
          res = resource.append datum

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

    def append url, datum
      con = JSONResource::Connection.new url
      con.append datum
    end

    private

    def start url, &block
      JSONResource::Connection.new(url).start block
    end
  end
end
