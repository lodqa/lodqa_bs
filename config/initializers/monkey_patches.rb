# Monkey patch for SuckerPunch::Job::ClassMethods.
# This patch is needed to run job in different thread pool per job class.
# Original source code at:
# https://github.com/brandonhilkert/sucker_punch/blob/v3.1.0/lib/sucker_punch/job.rb#L35-L39
SuckerPunch::Job::ClassMethods.define_method :perform_async do |*args|
  return unless SuckerPunch::RUNNING.true?

  job_data = args.first
  queue = SuckerPunch::Queue.find_or_create(job_data[:job_class], num_workers, num_jobs_max)
  queue.post { __run_perform(*args) }
end

# Monkey patch for ActiveJob::QueueAdapters::SuckerPunchAdapter.
# This patch is needed to show the queue name in logs.
# Do not consider sucker punch 1.0 API.
# Original source code at
# https://github.com/rails/rails/blob/7-1-stable/activejob/lib/active_job/queue_adapters/sucker_punch_adapter.rb#L21-L29
ActiveJob::QueueAdapters::SuckerPunchAdapter.define_method :enqueue do |job|
  # To show the queue name in logs.
  job.queue_name = job.class.to_s
  ActiveJob::QueueAdapters::SuckerPunchAdapter::JobWrapper.perform_async job.serialize
end
