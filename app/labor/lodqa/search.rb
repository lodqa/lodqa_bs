# frozen_string_literal: true

require 'concurrent/promises'
require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

module Lodqa
  # Search the query by the LODQA
  module Search
    class << self
      def start search, on_start, on_event, logger
        tasks = search_for_datasets_async search, on_event, logger

        on_start.call

        states = wait_for_completion_of_all tasks
        on_event.call :finish, states: states
        message = "Search finished. search_id: #{search.search_id}, states: #{JSON.generate states}"
        logger.info message
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

      def search_for_datasets_async search, on_event, logger
        if search.target.present?
          search_for_a_dataset_async search, on_event, logger
        else
          search_for_all_datasets_async search, on_event, logger
        end
      end

      def search_for_a_dataset_async search, on_event, logger
        dataset = Sources.dataset_of_target search.target
        dataset = dataset.merge(number: 1)
        [Concurrent::Promises.future { search_for dataset, search, on_event, logger }]
      end

      def search_for_all_datasets_async search, on_event, logger
        Sources.all_datasets
               .map.with_index(1) { |dataset, number| dataset.merge(number: number) }
               .map { |dataset| Concurrent::Promises.future { search_for dataset, search, on_event, logger } }
      end

      def search_for dataset, search, on_event, logger
        executor = OneByOneExecutor.new dataset,
                                        search.query,
                                        search.search_id,
                                        read_timeout: search.read_timeout,
                                        sparql_limit: search.sparql_limit,
                                        answer_limit: search.answer_limit,
                                        logger: logger,
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
