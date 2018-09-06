# frozen_string_literal: true

# The on memory container of subscriptions of search.
# If there are subscriptions of a search, the Event of the search will be sent when it is created.
class SubscriptionContainer
  @container = []
  @semaphore = Mutex.new

  class << self
    # Add a subscription for the search.
    def add_for search, url
      @semaphore.synchronize do
        @container = @container.concat [[
          search.search_id,
          Channel.new(url)
        ]]
      end
    end

    # Remove all subscriptions for the search.
    def remove_all_for search
      @semaphore.synchronize do
        @container = @container.reject { |s| s[0] == search.search_id }
      end
    end

    # Publish a event of the search to subscribers.
    def publish_for search, event
      select(search.search_id).each do |_, channel|
        channel.transmit events: [event]
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
      end
    end

    private

    def select search_id
      @container.select { |s| s[0] == search_id }
    end
  end
end
