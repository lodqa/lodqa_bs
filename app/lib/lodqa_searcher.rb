# frozen_string_literal: true

require 'concurrent/edge/promises'

# Search by LODQA
module LoqdaSearcher
  class << self
    def perform query, on_start, on_event
      tasks = execute_on_all_datasets query, on_event

      on_start.call

      # Call value! method to catch errors in sub threads.
      Concurrent::Promises.zip(*tasks).value!
      Time.now
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

    def execute_on_all_datasets query, on_event
      Lodqa::Sources.datasets.map.with_index 1 do |dataset, number|
        Concurrent::Promises.future { execute_on_a_dataset query, on_event, dataset, number }
      end
    end

    def execute_on_a_dataset query, on_event, dataset, number
      executor = Lodqa::OneByOneExecutor.new dataset.merge(number: number),
                                             query.statement,
                                             query.query_id,
                                             debug: false
      # Bind events to save events
      executor.on(*EVENTS_TO_SAVE) do |event, data|
        on_event.call event, data
      end

      executor.perform
    end
  end
end
