# frozen_string_literal: true

class Search < ApplicationRecord
  # Subscribe search
  module Subscribable
    OFFSET_SIZE = 100

    extend ActiveSupport::Concern

    def subscribe url
      subsribe_serach_if_running self, url
      notify_existing_events_to url, self
    rescue Errno::ECONNREFUSED, Net::OpenTimeout, SocketError => e
      logger.info "Establishing TCP connection to #{url} failed. Error: #{e.inspect}"
    end

    private

    # There is no trigger to delete subscription of finished search.
    def subsribe_serach_if_running search, url
      search.not_finished? do
        DbConnection.using { SubscriptionContainer.add_for search, url }
      end
    end

    def notify_existing_events_to url, search
      search.occurred_events(OFFSET_SIZE).each { |e| JSONResource.append_all url, events: e }
    end
  end
end
