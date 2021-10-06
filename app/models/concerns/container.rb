# frozen_string_literal: true

# The on memory container of subscriptions of search.
module Container
  extend ActiveSupport::Concern

  included do
    @container = {}
    @semaphore = Mutex.new
  end

  class_methods do
    # Add a channel for the search.
    def add_for search, url
      @semaphore.synchronize do
        channels = @container[search.search_id] || []
        @container[search.search_id] = channels.concat [Channel.new(url)]
      end
    end

    # Remove all channels for the search.
    def remove_all_for search_id
      @semaphore.synchronize do
        @container.delete search_id
      end
    end

    # Publish data to channels of the search.
    def publish_for search, data
      each_channels_of search do |channel|
        channel.transmit format(data)
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        Rails.logger.info "Establishing TCP connection to #{channel} failed. Error: #{e.inspect}"
      end
    end

    private

    # A hook method to format data
    def format data
      data
    end

    def each_channels_of search, &block
      channels = @container[search.search_id] || []
      channels.each(&block)
    end
  end
end
