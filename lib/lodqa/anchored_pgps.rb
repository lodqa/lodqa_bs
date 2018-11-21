# frozen_string_literal: true

require 'logger/loggable'

module Lodqa
  class AnchoredPgps
    include Logger::Loggable

    def initialize pgp, mappings
      @pgp = pgp
      @mappings = mappings
    end

    def each &block
      logger.debug "start #{self.class.name}##{__method__}"
      anchored_pgps(@pgp, @mappings).each(&block)
    end

    private

    def anchored_pgps pgp, mappings
      Enumerator.new do |anchored_pgps|
        pgp[:nodes].delete_if { |n| nodes_to_delete(pgp, mappings).include? n }
        pgp[:edges].uniq!
        terms = pgp[:nodes].values.map { |n| mappings[n[:text].to_sym] }

        terms.map! { |t| t.nil? ? [] : t }

        logger.debug "terms: #{terms.first.product(*terms.drop(1))}"

        terms.first
             .product(*terms.drop(1))
             .each do |ts|
               anchored_pgp = pgp.dup
               anchored_pgp[:nodes] = pgp[:nodes].dup
               anchored_pgp[:nodes].each_key { |k| anchored_pgp[:nodes][k] = pgp[:nodes][k].dup }
               anchored_pgp[:nodes].each_value.with_index { |n, i| n[:term] = ts[i] }

               anchored_pgps << anchored_pgp
             end
      end
    end

    def nodes_to_delete pgp, mappings
      logger.debug "start #{self.class.name}##{__method__}"

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
  end
end
