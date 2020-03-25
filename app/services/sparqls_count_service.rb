# frozen_string_literal: true

require 'lodqa/graph_finder'
require 'sparql_client/cacheable_client'

# returns the count of sparqls
module SparqlsCountService
  class << self
    # Handle sparqls count.
    def sparqls_count param
      sparql_client = SparqlClient::CacheableClient.new(param.endpoint_url, param.endpoint_options)
      finder = Lodqa::GraphFinder.new(sparql_client, param.graph_uri, param.graph_finder_options)

      sparqls = []
      anchored_pgps(param.pgp, param.mappings).each do |anchored_pgp|
        to_sparql(anchored_pgp, finder) { |sparql| sparqls << sparql }
      end

      sparqls.count
    end

    private

    # rubocop:disable Metrics/AbcSize
    def anchored_pgps pgp, mappings
      anchored_pgps = []
      pgp[:nodes].delete_if { |n| nodes_to_delete(pgp, mappings).include? n }
      pgp[:edges].uniq!
      terms = pgp[:nodes].values.map { |n| mappings[n[:text].to_sym] }

      terms.map! { |t| t.nil? ? [] : t }

      terms.first.product(*terms.drop(1))
           .each do |ts|
        anchored_pgp = pgp.dup
        anchored_pgp[:nodes] = pgp[:nodes].dup
        anchored_pgp[:nodes].each_key { |k| anchored_pgp[:nodes][k] = pgp[:nodes][k].dup }
        anchored_pgp[:nodes].each_value.with_index { |n, i| n[:term] = ts[i] }

        anchored_pgps << anchored_pgp
      end

      anchored_pgps
    end
    # rubocop:enable Metrics/AbcSize

    def to_sparql anchored_pgp, graph_finder
      graph_finder.sparqls_of(anchored_pgp) do |_bgp, sparql|
        yield sparql
      end
    end

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    def nodes_to_delete pgp, mappings
      nodes_to_delete = []
      pgp[:nodes].each_key do |n|
        next unless mappings[pgp[:nodes][n][:text]].nil? || mappings[pgp[:nodes][n][:text]].empty?

        connected_nodes = []
        pgp[:edges].each { |e| connected_nodes << e[:object] if e[:subject] == n }
        pgp[:edges].each { |e| connected_nodes << e[:subject] if e[:object] == n }

        # if it is a passing node
        next unless connected_nodes.length == 2

        nodes_to_delete << n
        pgp[:edges].each do |e|
          e[:object]  = connected_nodes[1] if e[:subject] == connected_nodes[0] && e[:object] == n
          e[:subject] = connected_nodes[1] if e[:subject] == n && e[:object] == connected_nodes[0]
          e[:object]  = connected_nodes[0] if e[:subject] == connected_nodes[1] && e[:object] == n
          e[:subject] = connected_nodes[0] if e[:subject] == n && e[:object] == connected_nodes[1]
        end
      end
      nodes_to_delete
    end
    # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
  end
end
