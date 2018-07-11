require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

class LodqaSearchJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    logger.fatal exception
  end

  def perform(*args)
    query = args[0]

    result = execute query do
      # TODO: call the callback with an accepting query event
      p 'Searching the query have been starting.'
    end

    # TODO: call the callback with finishing query event
    p result
  end

  def execute(query)
    start_time = Time.now
    threads = execute_on_all_datasets query

    yield

    answer_set = threads.each_with_object({}) { |t, summary| t.join.value.each { |a| summary[a[:uri]] = a[:label] } }
    "Elapsed time: #{Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')}\n\n" +
      JSON.pretty_generate(answer_set.map { |k, v| { url: k, label: v } })
  end

  def execute_on_all_datasets(query)
    Lodqa::Sources.datasets.map do |dataset|
      Thread.start do
        executor = Lodqa::OneByOneExecutor.new dataset, query

        # Bind events to colletc answers
        collected_answers = []
        executor.on(:answer) { |_, val| collected_answers << val[:answer] }

        executor.perform

        collected_answers
      end
    end
  end
end
