# frozen_string_literal: true

# The channels.
require 'http'

# All channesls share unreachable url.
class Channel
  # A Set of urls that is failed to send any message.
  @unreachable_url = Set.new

  class << self
    attr_reader :unreachable_url
  end

  def initialize url
    @url = url

    # Delete re-registered url.
    self.class.unreachable_url.delete url
  end

  # Transmit a event of the search to subscribers.
  def transmit data
    return if self.class.unreachable_url.member? @url
    HTTP.post @url, data
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError
    self.class.unreachable_url << @url
    raise
  end
end
