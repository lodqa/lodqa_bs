# frozen_string_literal: true

require 'sparql/client'
require 'logger/loggable'
require 'sparql_client/endpoint_error'
require 'sparql_client/endpoint_temporary_error'
require 'sparql_client/endpoint_timeout_error'
require 'concurrent/executor/thread_pool_executor'

# Cache results of sparql to speed up SPARQL queries.
module SparqlClient
  class CacheableClient
    include Logger::Loggable

    DEFAULT_EXECUTOR_OPTIONS = {
      min_threads: 0,
      max_threads: 20,
      auto_terminate: true,
      idletime: 60, # 1 minute
      max_queue: 0, # unlimited
      fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
    }.freeze

    def initialize endpoint_url, parallel = 16, endpoint_options = {}
      @endpoint_url = endpoint_url

      endpoint_options[:read_timeout] ||= 60
      # Set default HTTP method to GET.
      # Default HTTP method of SparqlClient is POST.
      # But POST method in HTTP 1.1 may occurs conection broken error.
      # If HTTP method is GET, when HTTP connection error occurs, a request is retried by HTTP stack of Ruby standard library.
      endpoint_options[:method] ||= :get
      @client = SPARQL::Client.new endpoint_url, endpoint_options
      @cache = {}
      @executor = Concurrent::ThreadPoolExecutor.new DEFAULT_EXECUTOR_OPTIONS.merge max_threads: parallel
    end

    # Query a SPARQL asynchronously.
    # This function is implemented with threads, so pass back an error in 1st parameter of return values.
    # example:
    # client.query_async(sparql) do | err, result |
    #   if err
    #     # handle an error
    #   else
    #     # handle a result
    #   end
    # end
    def query_async sparql
      @executor.post do
        yield [nil, query(sparql)]
      rescue StandardError => e
        yield [e, nil]
      end
    end

    def query sparql
      if @cache.key? sparql
        @cache[sparql]
      else
        begin
          @client.query(sparql).tap { |result| @cache[sparql] = result }
        rescue Net::HTTP::Persistent::Error => e
          # A timeout error was reterned from the Endpoint
          logger.debug 'SPARQL Timeout Error', error_messsage: e.message, trace: e.backtrace
          raise EndpointTimeoutError.new e, @endpoint_url, sparql
        rescue SPARQL::Client::ServerError, SocketError, Errno::ECONNREFUSED, Net::OpenTimeout => e
          # A temporary error was reterned from the Endpoint
          logger.debug 'SPARQL Endpoint Temporary Error', error_messsage: e.message, trace: e.backtrace
          raise EndpointTemporaryError.new e, @endpoint_url, sparql
        rescue OpenSSL::SSL::SSLError, SPARQL::Client::ClientError => e
          # TODO: What is the SPARQL::Client::ClientError?
          logger.debug 'SPARQL Endpoint Persistent Error', error_messsage: e.message, trace: e.backtrace
          raise EndpointError.new e, @endpoint_url
        rescue StandardError => e
          logger.error e, message: 'Unknown Error occurs during request SPARQL to the Endpoint'
          raise e
        end
      end
    end

    def select *args
      @cilent.select(*args)
    end
  end
end
