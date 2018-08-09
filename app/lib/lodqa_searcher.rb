# frozen_string_literal: true

# Search by LODQA
module LoqdaSearcher
  class << self
    def perform query
      threads = execute_on_all_datasets query

      yield

      threads.each(&:join)
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

    def execute_on_all_datasets query
      Lodqa::Sources.datasets.map.with_index 1 do |dataset, number|
        Thread.start { execute_on_a_dataset query, dataset, number }
      end
    end

    def execute_on_a_dataset query, dataset, number
      executor = Lodqa::OneByOneExecutor.new dataset.merge(number: number),
                                             query.statement,
                                             debug: false
      # Bind events to save events
      executor.on(*EVENTS_TO_SAVE) do |event, data|
        DbConnection.using do
          Event.create query: query,
                       event: event,
                       data: { event: event }.merge(data)
        end
      end

      executor.perform
    end
  end
end
