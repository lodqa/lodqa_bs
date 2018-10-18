# frozen_string_literal: true

module JSONResource
  # HTTP Connction
  class Connection
    def initialize url
      @uri = URI url
      @http = Net::HTTP.new @uri.hostname, @uri.port
      @http.use_ssl = @uri.instance_of? URI::HTTPS
    end

    def open!
      @http.start
    end

    def opened?
      @http.started?
    end

    # To send multiple data via same conneciton.
    def start block
      @http.start
      block.call self
      @http.finish
    end

    # Send single datum
    def append datum
      req = Net::HTTP::Post.new @uri.path, 'Content-Type' => 'application/json'
      req.body = datum.to_json
      res = @http.request req

      return nil if res.is_a? Net::HTTPSuccess
      res
    end
  end
end
