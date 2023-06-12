# frozen_string_literal: true

require 'lodqa/graphicator'

# Business logic about registering a search
module RegisterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search and pgp exists.
    # Call back only if same search or pgp exists.
    def register search_param
      search, pgp = detect_duplicate search_param
      return start_callback_job_with search, search_param.callback_url if search

      start_new_search search_param, pgp
    end

    private

    def detect_duplicate search_param
      if search_param.simple_mode?
        # Different natural language queries may result in the same pgp
        # even if the natural language queries are different,
        # for example, if the number of whitespace strings in
        # the natural language queries are different.
        pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern search_param.query
        search = PseudoGraphPattern.equals_in(pgp, search_param)&.searches&.first
      else
        pgp = search_param.pgp
        search = Search.expert_equals_in search_param
      end

      [search, pgp]
    end

    def start_new_search search_param, pgp
      pseudo_graph_pattern = PseudoGraphPattern.create pgp:,
                                                       target: search_param.target,
                                                       read_timeout: search_param.read_timeout,
                                                       sparql_limit: search_param.sparql_limit,
                                                       answer_limit: search_param.answer_limit,
                                                       private: search_param.private
      create_term_mapping pseudo_graph_pattern, search_param unless search_param.simple_mode?

      start_search_job search_param, pseudo_graph_pattern
    end

    # Call back events about an exiting search.
    def start_callback_job_with search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end

    # Start new job for new search.
    def start_search_job search_param, pseudo_graph_pattern
      search = create_search pseudo_graph_pattern

      SearchJob.perform_later search.search_id
      search.register_callback search_param.callback_url

      search.search_id
    end

    def create_term_mapping pseudo_graph_pattern, search_param
      TermMapping.create pseudo_graph_pattern:,
                         dataset_name: search_param.target,
                         mapping: search_param.mappings
    end

    def create_search pseudo_graph_pattern
      search = Search.new(pseudo_graph_pattern:)
      search.assign_id!
      search.be_referred!
      search
    end
  end
end
