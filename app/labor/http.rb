# frozen_string_literal: true

# Send JSON message by HTTP POST mesthod.
module HTTP
  class << self
    def post url, datum
      http = HTTP::Conneciton.new(url)
      http.post datum
    end

    def start url, &block
      HTTP::Conneciton.new(url).start block
    end
  end

  # HTTP Connction
  class Conneciton
    def initialize url
      @uri = URI url
      @http = Net::HTTP.new @uri.hostname, @uri.port
      @http.use_ssl = @uri.instance_of? URI::HTTPS
    end

    # To send multiple data via same conneciton.
    def start block
      @http.start
      block.call self
      @http.finish
    end

    # Send single datum
    def post datum
      req = Net::HTTP::Post.new @uri.path, 'Content-Type' => 'application/json'
      req.body = datum.to_json
      res = @http.request req

      return nil if res.is_a? Net::HTTPSuccess
      res
    end
  end
end
