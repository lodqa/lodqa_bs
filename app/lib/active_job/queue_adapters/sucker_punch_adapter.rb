# frozen_string_literal: true

module ActiveJob
  module QueueAdapters
    # SuckerPunchAdapter calls all jobs as JobWrapper class jobs.
    # Unable to acquire setting information on a per job class basis.
    # It is a monkey patch to solve this.
    # see: https://github.com/rails/rails/blob/b2eb1d1c55a59fee1e6c4cba7030d8ceb524267c/activejob/lib/active_job/queue_adapters/sucker_punch_adapter.rb#L24
    class SuckerPunchAdapter
      def enqueue job
        # In order to log the correct queue name, set the class name as the queue name.
        job.queue_name = job.class.to_s

        # Register the job in the queue using the perform_async method of the job
        # so that information on the job can be retrieved.
        # In order to output the start of the job to the log,
        # the job is executed using the ActiveJob::Base.execute method.
        job.class.perform_async { Base.execute job.serialize }
      end
    end
  end
end
