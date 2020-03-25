# frozen_string_literal: true

require 'logger'

class Logger::Logger
  attr_reader :query_id

  $stdout.sync = true

  class << self
    def generate_request_id
      SecureRandom.uuid.tap { |id| self.request_id = id }
    end

    def request_id
      Thread.current.thread_variable_get(:request_id)
    end

    def request_id= id
      Thread.current.thread_variable_set(:request_id, id)
    end
  end

  def initialize query_id, logger, log_level
    @query_id = query_id

    # When used with Rails, you can specify a logger from outside.
    @log = if logger
             logger
           else
             stdout = ::Logger.new STDOUT
             stdout.level = log_level
             stdout
           end
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
      error_message: error&.message,
      class: error&.class.to_s,
      trace: error&.backtrace
    }.merge(rest)

    @log.error error_info.to_json.to_s
  end
end
