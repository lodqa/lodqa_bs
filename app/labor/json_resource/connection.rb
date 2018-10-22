# frozen_string_literal: true

module JSONResource
  # HTTP Connction
  class Connection
    def initialize url
      @uri = URI url
      @http = Net::HTTP.new @uri.hostname, @uri.port
      @http.use_ssl = @uri.instance_of? URI::HTTPS
      @semaphore = Mutex.new
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
      # Net::HTTP may not be thread-safe.
      # Actually, the state of Net::Protocol may be corrupted while writing from multiple threads.
      # We guarantee synchronous writing using Mutex#synchronize.
      # see https://stackoverflow.com/questions/3063088/is-rubys-nethttp-threadsafe
      res = @semaphore.synchronize { @http.request req }

      return nil if res.is_a? Net::HTTPSuccess
      res
    end
  end
end
