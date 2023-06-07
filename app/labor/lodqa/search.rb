# frozen_string_literal: true

require 'concurrent/promises'
require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

module Lodqa
  # Search the query by the LODQA
  module Search
    class << self
      def start pseudo_graph_pattern, dialogs, on_start, on_event, logger
        tasks = search_for_datasets_async pseudo_graph_pattern, dialogs, on_event, logger

        on_start.call

        states = wait_for_completion_of_all tasks
        on_event.call(:finish, states:)

        message = "Search finished. pgp id: #{pseudo_graph_pattern.id}, " \
                  "states: #{JSON.generate states}"
        logger.info message
      end

      private

      EVENTS_TO_SAVE = %i[
        datasets
        pgp
        mappings
        sparql
        anchored_pgp
        query_sparql
        solutions
        answer
        gateway_error
      ].freeze

      def search_for_datasets_async pseudo_graph_pattern, dialogs, on_event, logger
        pseudo_graph_pattern.target.split(',')
                            .map { |target| Sources.dataset_of_target target }
                            .map.with_index(1) { |dataset, number| dataset.merge(number:) }
                            .map do |dataset|
          Concurrent::Promises.future do
            search_for dataset, pseudo_graph_pattern, dialogs, on_event, logger
          end
        end
      end

      def search_for dataset, pseudo_graph_pattern, dialogs, on_event, logger
        executor = OneByOneExecutor.new dataset,
                                        pseudo_graph_pattern.pgp.deep_symbolize_keys,
                                        pseudo_graph_pattern.id,
                                        term_mappings(pseudo_graph_pattern),
                                        read_timeout: pseudo_graph_pattern.read_timeout,
                                        sparql_limit: pseudo_graph_pattern.sparql_limit,
                                        answer_limit: pseudo_graph_pattern.answer_limit,
                                        logger:,
                                        debug: false

        # Bind events to save events
        executor.on(*EVENTS_TO_SAVE) { |event, data| on_event.call event, data }
        executor.perform
      end

      def wait_for_completion_of_all tasks
        # Call value! method to catch errors in sub threads.
        Concurrent::Promises.zip(*tasks).value!
      end

      def term_mappings pgp
        pgp.term_mappings.present? ? pgp.term_mappings[0].mapping.deep_symbolize_keys : nil
      end
    end
  end
end
