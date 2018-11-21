# frozen_string_literal: true

# The channels.
# All channesls share unreachable url.
class Channel
  # Share a connection to the same resource
  @connections = {}
  # A Set of urls that is failed to send any message.
  @unreachable_url = Set.new

  class << self
    attr_reader :connections, :unreachable_url
  end

  def initialize url
    @url = url
    self.class.connections[url] = JSONResource::Connection.new(url)

    # Remove re-registered url from the deny list.
    self.class.unreachable_url.delete url
  end

  # Transmit a event of the search to subscribers.
  def transmit data
    return if self.class.unreachable_url.member? @url

    conn = self.class.connections[@url]

    # It may take time to open a connection.
    # Instead of opening a connection at initialization, open a connection when using a connection.
    conn.open!
    conn.append data
  rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError
    self.class.unreachable_url << @url
    raise
  end

  # Show URL for logging.
  def to_s
    @url
  end
end
