# frozen_string_literal: true

require 'concurrent/executor/thread_pool_executor'

class Logger
  module Async
    DEFAULT_EXECUTOR_OPTIONS = {
      min_threads:     0,
      max_threads:     20,
      auto_terminate:  true,
      idletime:        60, # 1 minute
      max_queue:       0, # unlimited
      fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
    }.freeze

    @executor = Concurrent::ThreadPoolExecutor.new DEFAULT_EXECUTOR_OPTIONS

    def self.defer
      @executor.post do
        yield
      end
    end
  end
end
