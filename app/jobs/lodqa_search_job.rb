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

    elapsed_time = execute request_id, query do
      # TODO: call the callback with an accepting query event
      p "Searching the query #{request_id} have been starting."
    end

    # TODO: call the callback with finishing query event
    p "Elapsed time: #{Time.at(elapsed_time).utc.strftime('%H:%M:%S')}"
    p Answer.select(:uri, :label).where(request_id: request_id).as_json(except: :id)
  end

  private

  def execute(request_id, query)
    start_time = Time.now
    threads = execute_on_all_datasets request_id, query

    yield

    threads.each(&:join)
    Time.now - start_time
  end

  def execute_on_all_datasets(request_id, query)
    Lodqa::Sources.datasets.map do |dataset|
      Thread.start do
        executor = Lodqa::OneByOneExecutor.new dataset, query, debug: false

        # Bind events to save answers
        executor.on(:answer) do |_, val|
          begin
            Answer.create request_id: request_id, uri: val[:answer][:uri], label: val[:answer][:label]
          rescue ActiveRecord::RecordNotUnique
            logger.debug "Duplicated answer: request_id: #{request_id}, uri: #{val[:answer][:uri]}"
          rescue StandardError => e
            logger.error "#{e.class}, #{e.message}"
          ensure
            ActiveRecord::Base.connection_pool.checkin Answer.connection
          end
        end

        executor.perform
      end
    end
  end
end
