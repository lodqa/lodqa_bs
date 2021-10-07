# frozen_string_literal: true

require 'logger'

class Logger::Logger
  attr_reader :query_id

  $stdout.sync = true

  def initialize query_id, logger, log_level
    @query_id = query_id

    # When used with Rails, you can specify a logger from outside.
    @log = if logger
             logger
           else
             stdout = ::Logger.new $stdout
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
    red = "\033[0;31m"
    dark_gray = "\033[0;33m"
    no_color = "\033[0m"
    message = "#{red}[DEBUG]#{no_color} query_id: #{id || query_id}, message: #{message}"
    @log.debug [message, *rest.map { |key, val| "#{key}: #{dark_gray}#{val}#{no_color}" }].join(', ')

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
