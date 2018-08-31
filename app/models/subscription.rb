# frozen_string_literal: true

# The on memory container of subscriptions of search.
# If there are subscriptions of a search, the Event of the search will be sent when it is created.
class Subscription
  @container = []
  @semaphore = Mutex.new

  # A Set of urls that is failed to send any message.
  @unreachable_url = Set.new

  class << self
    # Add a subscription for the search.
    def add_for search, url
      @semaphore.synchronize { @container = @container.concat [[search.search_id, url]] }

      # Delete re-registered url.
      @unreachable_url.delete url
    end

    # Remove all subscriptions for the search.
    def remove_all_for search
      @semaphore.synchronize { @container = @container.reject { |s| s[0] == search.search_id } }
    end

    # Publish a event of the search to subscribers.
    def publish event, search
      select(search.search_id).each do |_, url|
        next if @unreachable_url.member? url
        Notification.send url, events: [event]
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
        @unreachable_url << url
      end
    end

    private

    def select search_id
      @container.select { |s| s[0] == search_id }
    end
  end
end
