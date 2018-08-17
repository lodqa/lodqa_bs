# frozen_string_literal: true

require 'logger/logger'
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

    # Defer the process received as a block.
    # The process run in an another thread by EM.defer.
    # The request id for logging will be relayed automatically.
    def self.defer
      query_id = Logger.query_id

      @executor.post do
        Logger.query_id = query_id
        yield
      end
    end
  end
end
