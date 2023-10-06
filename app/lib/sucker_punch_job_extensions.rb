# frozen_string_literal: true

# Sucker Punch has a feature where it distinguishes thread pools based on the job class name.
# However, when invoked from ActiveJob, all jobs are wrapped in the JobWrapper class,
# which prevents this feature from working as expected.
# This patch is designed to identify the thread pool to use based on the job class.
module SuckerPunchJobExtensions
  def perform_async(*args)
    return unless SuckerPunch::RUNNING.true?

    job_data = args.first
    queue = SuckerPunch::Queue.find_or_create(job_data[:job_class], num_workers, num_jobs_max)
    queue.post { __run_perform(*args) }
  end
end
