# frozen_string_literal: true

# The channels.
# All channesls share unreachable url.
class Channel
  # A Set of urls that is failed to send any message.
  @@unreachable_url = Set.new # rubocop:disable Style/ClassVars

  def initialize url
    @url = url

    # Delete re-registered url.
    @@unreachable_url.delete url
  end

  # Transmit a event of the search to subscribers.
  def transmit data
    return if @unreachable_url.member? @url
    HTTP.post @url, data
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
    logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
    @@unreachable_url << url
  end
end
