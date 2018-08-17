# frozen_string_literal: true

require 'logger'

class Logger::Logger
  attr_reader :query_id

  $stdout.sync = true

  def initialize query_id, log_level
    @query_id = query_id
    @log = ::Logger.new STDOUT
    @log.level = log_level
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
end
