# frozen_string_literal: true

# The on memory container of subscriptions of search.
module Container
  extend ActiveSupport::Concern

  included do
    @container = {}
    @semaphore = Mutex.new
  end

  class_methods do
    # Add a subscription for the search.
    def add_for search, url
      @semaphore.synchronize do
        channels = @container[search.search_id] || []
        @container[search.search_id] = channels.concat [Channel.new(url)]
      end
    end

    # Remove all subscriptions for the search.
    def remove_all_for search
      @semaphore.synchronize do
        @container.delete search.search_id
      end
    end

    # Publish a event of the search to subscribers.
    def publish_for search, event
      select(search.search_id).each do |channel|
        channel.transmit events: [event]
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        Rails.logger.info "Establishing TCP connection to #{channel} failed. Error: #{e.inspect}"
      end
    end

    private

    def select search_id
      @container[search_id] || []
    end
  end
end
