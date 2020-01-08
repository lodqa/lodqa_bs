# frozen_string_literal: true

#
# It parses a query and produces its parse rendering and PGP.
#
require 'net/http'
require 'pp'
require 'enju_access/cgi_accessor'

module Lodqa; end unless defined? Lodqa

module Lodqa::Graphicator
  class << self
    def produce_pseudo_graph_pattern query
      raise ArgumentError, 'query should be given.' if query.nil? || query.empty?

      produce_pgp_from query
    end

    private

    def produce_pgp_from query
      parsed_query = EnjuAccess::CGIAccessor.parse query
      graphicate parsed_query
    end

    def graphicate parsed_query
      # [Exception Handling] Treat the entire sentence as a BNC when no BNC was found
      if parsed_query[:base_noun_chunks].empty?
        last_idx = parsed_query[:tokens].last[:idx]
        parsed_query[:base_noun_chunks] << { head: last_idx, beg: 0, end: last_idx }
      end

      nodes = nodes_from parsed_query

      # index the nodes by their heads
      node_index = node_index_from nodes

      edges = edges_from parsed_query, node_index

      post_process! nodes, edges

      focus = focus_from node_index, parsed_query

      {
        nodes: nodes,
        edges: edges,
        focus: focus.to_s
      }
    end

    def nodes_from parsed_query
      variable = 't0'
      parsed_query[:base_noun_chunks].each_with_object({}) do |c, nodes|
        variable = variable.next
        nodes[variable.to_sym] = {
          head: c[:head],
          text: parsed_query[:tokens][c[:beg]..c[:end]].collect { |t| t[:lex] }.join(' ')
        }
      end
    end

    def node_index_from nodes
      node_index = {}
      nodes.each_key { |k| node_index[nodes[k][:head]] = k }

      node_index
    end

    def edges_from parsed_query, node_index
      parsed_query[:relations].collect do |s, p, o|
        {
          subject: node_index[s].to_s,
          object: node_index[o].to_s,
          text: p.collect { |i| parsed_query[:tokens][i][:lex] }.join(' ')
        }
      end
    end

    def focus_from node_index, parsed_query
      # default rule: take the first one as the focus, if no grammatical focus is found.
      node_index[parsed_query[:focus]] || node_index.values.first
    end

    # post_processing may be dependent on Enju
    def post_process! nodes, edges
      # 'and' coordination
      edges.reject! { |e| e[:text] == 'and' }

      # 'have A as B' pattern
      edges_have_as = edges.find_all { |e| e[:text] == 'have as' }
      unless edges_have_as.empty?
        pairs_have_as = edges_have_as.group_by { |e| e[:object] }
        pairs_have_as.each do |obj, pair|
          edge_have = edges.find do |e|
            e[:text] == 'have' &&
              ((e[:subject] == pair.first[:subject] && e[:object] == pair.last[:subject]) || (e[:subject] == pair.last[:subject] && e[:object] == pair.first[:subject]))
          end
          if edge_have
            edge_have[:text] = nodes[obj.to_sym][:text]
            nodes.delete(obj.to_sym)
          end
        end
        edges.reject! { |e| e[:text] == 'have as' }
      end

      # 'have A and B as C' pattern
      edges_have_and_as = edges.find_all { |e| e[:text] == 'have and as' }
      edges_have_and_as.each do |edge_have_and_as|
        edges_and_as = edges.find_all { |e| e[:text] == 'and as' && e[:object] == edge_have_and_as[:object] }
        edges_have_and = edges_and_as.map { |edge_and_as| edges.find { |e| e[:text] == 'have and' && e[:object] == edge_and_as[:subject] } }
        edges_have_and.each { |e| e[:text] = nodes[edge_have_and_as[:object].to_sym][:text] }
        nodes.delete(edge_have_and_as[:object].to_sym)
      end
      edges.reject! { |e| e[:text] == 'have and as' }
      edges.reject! { |e| e[:text] == 'and as' }
    end
  end
end
