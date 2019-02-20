# frozen_string_literal: true

require 'lodqa/graphicator'

module Lodqa
  module PGPFactory
    def self.create parser_url, query
      Graphicator.produce_pseudo_graph_pattern query, parser_url
    end
  end
end
