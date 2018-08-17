# frozen_string_literal: true

require 'logger'

class Logger::Logger
  class << self
    $stdout.sync = true

    def level= level
      @log.level = level
    end

    def query_id
      Thread.current.thread_variable_get(:query_id)
    end

    def query_id= id
      Thread.current.thread_variable_set(:query_id, id)
    end

    def info message, id = nil, **rest
      @log.info({
        query_id: id || query_id,
        message: message
      }
        .merge(rest)
        .to_json.to_s)
    end

    def debug message, id = nil, **rest
      @log.debug({
        query_id: id || query_id,
        message: message
      }
          .merge(rest)
          .to_json.to_s)
    end

    def error error, **rest
      error_info = {
        query_id: query_id,
        message: error&.message,
        class: error&.class,
        trace: error&.backtrace
      }.merge(rest)

      @log.error error_info.to_json.to_s
    end

    protected

    def init
      @log = ::Logger.new(STDOUT)
    end
  end

  init
end
