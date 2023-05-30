# frozen_string_literal: true

require 'logger'

class Logger::Logger
  RED = "\033[0;31m"
  ORANGE = "\033[0;33m"
  NO_COLOR = "\033[0m"

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
      message:
    }
      .merge(rest)
      .to_json.to_s)
  end

  def debug type, **rest
    message = "#{RED}[DEBUG]#{NO_COLOR} query_id: #{query_id}, type: #{ORANGE}#{type}#{NO_COLOR}"
    @log.debug [message, *rest.map { |key, val| "#{ORANGE}#{key}#{NO_COLOR}: #{val}" }].join(', ')
  end

  def error error, **rest
    bc = ActiveSupport::BacktraceCleaner.new
    bc.add_filter   { |line| line.gsub(Rails.root.to_s, '') } # strip the Rails.root prefix
    bc.add_silencer { |line| /gems/.match?(line) } # skip any lines from puma or rubygems

    error_info = {
      query_id:,
      error_message: error&.message,
      class: error&.class.to_s,
      trace: bc.clean(error&.backtrace)
    }.merge(rest)

    @log.error "#{RED}[ERROR]#{NO_COLOR} #{error_info.to_json}"
  end
end
