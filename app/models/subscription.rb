# frozen_string_literal: true

# The on memory container of subscriptions of query.
# If there are subscriptions of a query, the Event of the query will be sent when it is created.
class Subscription
  @store = []

  class << self
    def add query_id, url
      @store = @store.concat [[query_id, url]]
    end

    def get query_id
      @store.select { |s| s[0] == query_id }
    end

    def remove query_id
      @store = @store.reject { |s| s[0] == query_id }
    end
  end
end
