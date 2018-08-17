# frozen_string_literal: true

require 'logger'

module Logger::Loggable
  def logger
    @logger
  end

  def logger= logger
    @logger = logger
  end
end
