# frozen_string_literal: true

class ExpertSearch
  include CanStartSearch

  def initialize pgp, read_timeout, sparql_limit, answer_limit, target, mappings, private,
                 callback_url
    @pgp = pgp
    @read_timeout = read_timeout
    @sparql_limit = sparql_limit
    @answer_limit = answer_limit
    @target = target
    @mappings = mappings
    @private = private
    @callback_url = callback_url
  end

  def run
    search = Search.equals_in @read_timeout,
                              @sparql_limit,
                              @answer_limit,
                              @target,
                              @mappings

    return start_callback_job_with search, @callback_url if search

    pseudo_graph_pattern = PseudoGraphPattern.create(pgp: @pgp,
                                                     target: @target,
                                                     read_timeout: @read_timeout,
                                                     sparql_limit: @sparql_limit,
                                                     answer_limit: @answer_limit,
                                                     private: @private)
    pseudo_graph_pattern.term_mappings.create dataset_name: @target,
                                              mapping: @mappings

    start_search_job pseudo_graph_pattern, @callback_url
  end
end
