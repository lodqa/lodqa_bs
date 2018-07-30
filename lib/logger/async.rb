# frozen_string_literal: true

require 'eventmachine'
require 'logger/logger'

class Logger
  module Async
    # Defer the process received as a block.
    # The process run in an another thread by EM.defer.
    # The request id for logging will be relayed automatically.
    def self.defer
      request_id = Logger.request_id

      # An EventMachine.reactor is not running when no WebSocket request recieved.
      # https://github.com/faye/faye-websocket-ruby/blob/master/lib/faye/websocket.rb#L39
      Thread.new { EventMachine.run } unless EventMachine.reactor_running?
      Thread.pass until EventMachine.reactor_running?

      EM.defer do
        Logger.request_id = request_id
        yield
      end
    end
  end
end
