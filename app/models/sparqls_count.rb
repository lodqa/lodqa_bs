# frozen_string_literal: true

require 'lodqa/anchored_pgps'
require 'lodqa/graph_finder'
require 'logger/logger'
require 'sparql_client/cacheable_client'

# returns the count of sparqls
module SparqlsCount
  class << self
    include Logger::Loggable

    # Handle sparqls count.
    def sparqls_count param
      parallel = 16
      sparql_client = SparqlClient::CacheableClient.new(param.endpoint_url,
                                                        parallel, param.endpoint_options)
      graph_finder = Lodqa::GraphFinder.new(sparql_client,
                                            param.graph_uri, param.graph_finder_options)

      sparqls_count = 0
      anchored_pgps = Lodqa::AnchoredPgps.new param.pgp, param.mappings
      anchored_pgps.logger = Logger::Logger.new 'sparqls_count', logger, Logger::INFO
      anchored_pgps.each do |anchored_pgp|
        graph_finder.sparqls_of(anchored_pgp) do |_bgp, _sparql|
          sparqls_count += 1
        end
      end

      sparqls_count
    end
  end
end
