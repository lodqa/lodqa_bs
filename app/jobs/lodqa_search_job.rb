require 'lodqa/sources'
require 'lodqa/one_by_one_executor'

class LodqaSearchJob < ApplicationJob
  queue_as :default

  rescue_from(StandardError) do |exception|
    logger.fatal exception
  end

  def perform(*args)
    request_id = job_id
    query = args[0]

    result = execute request_id, query do
      # TODO: call the callback with an accepting query event
      p "Searching the query #{request_id} have been starting."
    end

    # TODO: call the callback with finishing query event
    p result
  end

  def execute(request_id, query)
    start_time = Time.now
    threads = execute_on_all_datasets request_id, query

    yield

    answer_set = threads.each_with_object({}) { |t, summary| t.join.value.each { |a| summary[a[:uri]] = a[:label] } }
    "Elapsed time: #{Time.at(Time.now - start_time).utc.strftime('%H:%M:%S')}\n\n" +
      JSON.pretty_generate(answer_set.map { |k, v| { url: k, label: v } })
  end

  def execute_on_all_datasets(request_id, query)
    Lodqa::Sources.datasets.map do |dataset|
      Thread.start do
        executor = Lodqa::OneByOneExecutor.new dataset, query, debug: false

        # Bind events to colletc answers
        collected_answers = []
        executor.on(:answer) do |_, val|
          begin
            Answer.create request_id: request_id, uri: val[:answer][:uri], label: val[:answer][:label]

            collected_answers << val[:answer]
          rescue ActiveRecord::RecordNotUnique
            Rails.logger.debug "Duplicated answer: request_id: #{request_id}, uri: #{val[:answer][:uri].to_s}"
          rescue => e
            Rails.logger.orrer "#{e.class}, #{e.message}"
          ensure
            ActiveRecord::Base.connection_pool.checkin Answer.connection
          end
        end

        executor.perform

        collected_answers
      end
    end
  end
end
