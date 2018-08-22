# frozen_string_literal: true

# The on memory container of subscriptions of query.
# If there are subscriptions of a query, the Event of the query will be sent when it is created.
class Subscription
  @container = []
  @semaphore = Mutex.new

  # A Set of urls that is failed to send any message.
  @unreachable_url = Set.new

  class << self
    # Add a subscription for the query.
    def add_for query, url
      @semaphore.synchronize { @container = @container.concat [[query.query_id, url]] }

      # Delete re-registered url.
      @unreachable_url.delete url
    end

    # Remove all subscriptions for the query.
    def remove_all_for query
      @semaphore.synchronize { @container = @container.reject { |s| s[0] == query.query_id } }
    end

    # Publish a event of the query to subscribers.
    def publish event, query
      select(query.query_id).each do |_, url|
        next if @unreachable_url.member? url
        Notification.send url, events: [event]
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
        @unreachable_url << url
      end
    end

    private

    def select query_id
      @container.select { |s| s[0] == query_id }
    end
  end
end
