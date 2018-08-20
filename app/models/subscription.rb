# frozen_string_literal: true

# The on memory container of subscriptions of query.
# If there are subscriptions of a query, the Event of the query will be sent when it is created.
class Subscription
  @store = []
  @semaphore = Mutex.new

  class << self
    def add query_id, url
      @semaphore.synchronize { @store = @store.concat [[query_id, url]] }
    end

    def remove query_id
      @semaphore.synchronize { @store = @store.reject { |s| s[0] == query_id } }
    end

    def publish query, event_data, ng_urls
      select(query.query_id).each do |_, url|
        next if ng_urls.include? url
        Notification.send url, events: [event_data]
      rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
        logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
        ng_urls << url
      end
    end

    private

    def select query_id
      @store.select { |s| s[0] == query_id }
    end
  end
end
