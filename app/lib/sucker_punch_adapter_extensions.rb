# frozen_string_literal: true

# In the default configuration, logs always show "SuckerPunch(default)".
# This patch is designed to replace the "(default)" with the actual job class name
# to provide more clarity in log messages about which job is being executed.
module SuckerPunchAdapterExtensions
  def enqueue job
    # To show the queue name in logs.
    job.queue_name = job.class.to_s
    ActiveJob::QueueAdapters::SuckerPunchAdapter::JobWrapper.perform_async job.serialize
  end
end
