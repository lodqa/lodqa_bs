# frozen_string_literal: true

class Search < ApplicationRecord
  # Subscribe search
  module Subscribable
    OFFSET_SIZE = 100

    extend ActiveSupport::Concern

    def subscribe url
      subscribe_search_if_running url
      notify_existing_events_to url, self
    rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
      logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
    end

    def publish data
      SubscriptionContainer.publish_for self, data
    end

    private

    # There is no trigger to delete subscription of finished search.
    def subscribe_search_if_running url
      not_finished? do
        DbConnection.using { SubscriptionContainer.add_for self, url }
      end
    end

    def notify_existing_events_to url, search
      search.occurred_events(OFFSET_SIZE).each { |e| JsonResource.append_all url, events: e }
    end
  end
end
