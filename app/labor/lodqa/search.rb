# frozen_string_literal: true

require 'concurrent/edge/promises'
require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

module Lodqa
  # Search the query by the LODQA
  module Search
    class << self
      def start search, on_start, on_event
        tasks = search_for_all_datasets_async search, on_event

        on_start.call

        wait_for_completion_of_all tasks
      end

      private

      EVENTS_TO_SAVE = %i[
        datasets
        pgp
        mappings
        sparql
        query_sparql
        solutions
        answer
        gateway_error
      ].freeze

      def search_for_all_datasets_async search, on_event
        Sources.datasets.map.with_index 1 do |dataset, number|
          dataset = dataset.merge(number: number)
          Concurrent::Promises.future { search_for dataset, search, on_event }
        end
      end

      def search_for dataset, search, on_event
        executor = OneByOneExecutor.new dataset,
                                        search.query,
                                        search.search_id,
                                        debug: false
        # Bind events to save events
        executor.on(*EVENTS_TO_SAVE) { |event, data| on_event.call event, data }
        executor.perform
      end

      def wait_for_completion_of_all tasks
        # Call value! method to catch errors in sub threads.
        Concurrent::Promises.zip(*tasks).value!
      end
    end
  end
end
