# frozen_string_literal: true

module SuckerPunch
  module Job
    # This is a monkey patch.
    # Execute the block in order to start the job using ActiveJob::Base.execute method.
    module ClassMethods
      def perform_async *_args, &block
        return unless SuckerPunch::RUNNING.true?

        queue = SuckerPunch::Queue.find_or_create to_s, num_workers, num_jobs_max
        queue.post { __run_perform(&block) }
      end

      def __run_perform
        SuckerPunch::Counter::Busy.new(to_s).increment
        result = yield
        SuckerPunch::Counter::Processed.new(to_s).increment
        result
      rescue StandardError => e
        SuckerPunch::Counter::Failed.new(to_s).increment
        SuckerPunch.exception_handler.call e, self, args
      ensure
        SuckerPunch::Counter::Busy.new(to_s).decrement
      end
    end
  end
end
