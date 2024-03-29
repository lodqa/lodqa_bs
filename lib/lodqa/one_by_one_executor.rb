# frozen_string_literal: true

require 'logger/logger'
require 'logger/loggable'
require 'term/finder'
require 'lodqa/anchored_pgps'
require 'lodqa/graph_finder'
require 'lodqa/graphicator'
require 'enju_access/cgi_accessor'
require 'sparql_client/cacheable_client'

module Lodqa
  class OneByOneExecutor
    include Logger::Loggable

    attr_reader :pgp

    def initialize dataset,
                   pgp,
                   query_id,
                   mappings,
                   urilinks_url: 'https://urilinks.lodqa.org',
                   read_timeout: 5,
                   sparql_limit: nil,
                   answer_limit: nil,
                   logger: nil, debug: false

      @target_dataset = dataset
      @pgp = pgp
      @mappings = mappings
      @urilinks_url = urilinks_url
      @read_timeout = read_timeout
      @sparql_limit = sparql_limit
      @answer_limit = answer_limit

      self.logger = Logger::Logger.new query_id, logger, debug ? Logger::DEBUG : Logger::INFO

      # For event emitting
      @event_hadlers = {}
      @event_data = {}

      @sparql_count = 0

      logger.debug "Initialize OneByOneExecutor with #{self} "
    end

    # Bind event handler to events
    def on *events, &block
      return unless events.is_a? Array

      events.each do |e|
        @event_hadlers[e] = [] unless @event_hadlers[e]
        @event_hadlers[e].push block
      end
    end

    # Merage previouse event data and call all event handlers.
    def emit event, data
      @event_hadlers[event]&.each { |h| h.call event, data }
    end

    # rubocop:disable Metrics/MethodLength
    def perform
      start = Time.zone.now
      dataset = {
        name: @target_dataset[:name],
        number: @target_dataset[:number]
      }
      emit(:datasets, dataset:)

      # pgp
      pgp = @pgp
      emit(:pgp, dataset:, pgp:)

      # mappings
      mappings = @mappings.presence || mappings(pgp, @target_dataset[:dictionary_url], @target_dataset[:endpoint_url], @target_dataset[:name_predicates])
      emit(:mappings, dataset:, pgp:, mappings:)

      parallel = 16
      endpoint = SparqlClient::CacheableClient.new @target_dataset[:endpoint_url],
                                                   parallel,
                                                   method: :get,
                                                   read_timeout: @read_timeout
      endpoint.logger = logger

      count = 0
      queue = Queue.new # Wait finishing serach of all SPARQLs.
      known_sparql = Set.new # Skip serach when SPARQL is duplicated.

      anchored_pgps = AnchoredPgps.new pgp, mappings
      anchored_pgps.logger = logger
      anchored_pgps.each do |anchored_pgp|
        emit :anchored_pgp, anchored_pgp

        graph_finder_options = {
          max_hop: @target_dataset[:max_hop],
          ignore_predicates: @target_dataset[:ignore_predicates],
          sortal_predicates: @target_dataset[:sortal_predicates],
          sparql_limit: @sparql_limit,
          answer_limit: @answer_limit
        }
        graph_finder = GraphFinder.new endpoint, nil, graph_finder_options
        graph_finder.sparqls_of anchored_pgp do |bgp, sparql_query|
          # Skip querying duplicated SPARQL.
          next if known_sparql.member? sparql_query

          known_sparql << sparql_query

          invoke_sparql endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql_query, queue
          count += 1
        end
      end

      error = 0
      success = 0
      count.times do
        e, s = queue.pop
        error += 1 if e
        success += 1 if s
      end

      stats = {
        dataset:,
        duration: Time.zone.now - start
      }
      if (error + success).positive?
        stats = stats.merge parallel:,
                            sparqls: error + success,
                            error:,
                            success:,
                            error_rate: error / (error + success).to_f
      end
      logger.info "Finish stats: #{JSON.generate stats}"
      stats
    rescue EnjuAccess::EnjuError => e
      logger.debug e.message
      state = {
        dataset:,
        duration: Time.zone.now - start,
        state: 'The parser server is not available.'
      }
      emit :gateway_error, state
      state
    rescue Term::FindError
      state = {
        dataset:,
        duration: Time.zone.now - start,
        state: 'Terms were not found.'
      }
      emit :gateway_error, state
      state
    rescue SparqlClient::EndpointError => e
      logger.debug 'The SPARQL Endpoint has a persistent error, continue to the next Endpoint',
                   endpoint: e.endpoint_name,
                   error_message: e.message
      {
        dataset:,
        duration: Time.zone.now - start,
        state: 'The Sparql endpoint is not available.'
      }
    rescue StandardError => e
      logger.error e
      {
        dataset:,
        duration: Time.zone.now - start,
        state: 'Something is wrong.'
      }
    end
    # rubocop:enable Metrics/MethodLength

    def to_s
      "dataset: pgp: #{@pgp}, #{@target_dataset[:name]}, read_timeout: #{@read_timeout}, sparql_limit: #{@sparql_limit}, answer_limit: #{@answer_limit}"
    end

    private

    def invoke_sparql endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql_query, queue
      @sparql_count += 1
      sparql = {
        query: sparql_query,
        number: @sparql_count
      }

      emit(:sparql, dataset:, pgp:, mappings:, anchored_pgp:, bgp:, sparql:)

      # Get solutions of SPARQL
      get_solutions_of_sparql_async endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql, queue

      # Emit an event to notify starting of querying the SPARQL.
      emit :query_sparql, dataset:, pgp:, mappings:, anchored_pgp:, bgp:, sparql:
    end

    def get_solutions_of_sparql_async endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql, queue
      # Get solutions of SPARQL
      endpoint.query_async sparql[:query] do |e, result|
        case e
        when nil
          # Convert to a hash object that contains only simple strings from array of RDF::Query::Solution.
          solutions = result.map { |s| s.to_h.transform_values(&:to_s) }

          emit(:solutions, dataset:, pgp:, mappings:, anchored_pgp:, bgp:, sparql:, solutions:)

          # Find the answer of the solutions.
          solutions.each do |solution|
            solution
              .select { |id| anchored_pgp[:focus] == id.to_s.gsub(/^i/, '') } # The answer is instance node of focus node.
              .each { |_, uri| get_label_of_url endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql, solutions, solution, uri }
          end
        when SparqlClient::EndpointTemporaryError
          logger.info "The SPARQL Endpoint #{e.endpoint_name} return a temporary error for #{e.sparql}, continue to the next SPARQL", error_message: e.message
          emit :solutions,
               dataset:, pgp:, mappings:, anchored_pgp:, bgp:, sparql:, solutions: [],
               error_message: 'endopoint temporary error'
        else
          logger.error e
        end

        queue.push [e, result]
      end
    end

    def get_label_of_url endpoint, dataset, pgp, mappings, anchored_pgp, bgp, sparql, solutions, solution, uri
      # WebSocket message will be disorderd if additional informations are get ascynchronously
      label = label endpoint, uri
      urls, first_rendering = forwarded_urls uri

      emit :answer,
           dataset:, pgp:, mappings:, anchored_pgp:, bgp:, sparql:, solutions:,
           solution:,
           answer: { uri:, label:, urls: urls&.select { |u| u[:forwarding][:url].length < 10_000 }, first_rendering: }
    end

    def mappings pgp, dictionary_url, endpoint_url, name_predicates
      keywords = pgp[:nodes].values.pluck(:text).concat(pgp[:edges].pluck(:text))

      return unless dictionary_url

      begin
        tf = Term::Finder.new dictionary_url, endpoint_url, name_predicates
        tf.logger = logger
        tf.find keywords
      rescue Term::Redirect => e
        tf = Term::Finder.new e.message
        tf.logger = logger
        tf.find keywords
      end
    end

    # Return label as stirng
    def label endpoint, uri
      query_for_solution = "select ?label where { <#{uri}>  rdfs:label ?label }"
      endpoint.query(query_for_solution).map { |s| s.to_h[:label] }.first.to_s
    end

    def forwarded_urls uri
      urls = RestClient.get "#{@urilinks_url}/url/translate.json?query=#{uri}" do |res|
        return nil unless res.code == 200

        JSON.parse(res.body, symbolize_names: true)[:results]
            .sort_by { |m| [- m[:matching_score], - m[:priority]] }
      end

      first_rendering = urls.find { |u| u.dig(:rendering, :mime_type)&.start_with? 'image' }&.dig :rendering
      [urls, first_rendering]
    rescue Errno::ECONNREFUSED, RestClient::Exceptions::ReadTimeout, SocketError => e
      logger.debug "Failed to conntect The URL forwarding DB at #{@urilinks_url}, continue to the next SPARQL", error_message: e.message
      nil
    end
  end
end
