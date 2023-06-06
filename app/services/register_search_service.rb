# frozen_string_literal: true

require 'lodqa/graphicator'

# Business logic about registering a search
module RegisterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search and pgp exists.
    # Call back only if same search or pgp exists.
    def register search_param
      if search_param.simple_mode?
        simple_mode search_param
      else
        expert_mode search_param
      end
    end

    private

    def simple_mode search_param
      dup_search = Search.simple_equals_in(search_param)
      return use_cache dup_search, search_param if dup_search

      pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern search_param.query

      # Different natural language queries may result in the same pgp
      # even if the natural language queries are different,
      # for example, if the number of whitespace strings in
      # the natural language queries are different.
      dup_pgp = PseudoGraphPattern.equals_in pgp, search_param

      if dup_pgp
        return start_callback_job_with_pgp search_param.query,
                                           dup_pgp,
                                           search_param.callback_url
      end

      start_search_job search_param, pgp, search_param.callback_url
    end

    def expert_mode search_param
      dup_search = Search.expert_equals_in(search_param)
      return use_cache dup_search, search_param if dup_search

      start_search_job search_param, search_param.pgp, search_param.callback_url
    end

    def use_cache dup_search, search_param
      dup_search.append_dialog search_param.user_id if search_param.user_id.present?
      start_callback_job_with_search dup_search, search_param.callback_url
    end

    # Call back events about an exiting search.
    def start_callback_job_with_search search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end

    # Call back events about an exiting pgp with new search.
    def start_callback_job_with_pgp query, pseudo_graph_pattern, callback_url
      search = create_search query, pseudo_graph_pattern
      start_callback_job_with_search search, callback_url
    end

    # Start new job for new search.
    def start_search_job search_param, pgp, callback_url
      pseudo_graph_pattern = PseudoGraphPattern.create pgp:,
                                                       target: search_param.target,
                                                       read_timeout: search_param.read_timeout,
                                                       sparql_limit: search_param.sparql_limit,
                                                       answer_limit: search_param.answer_limit,
                                                       private: search_param.private
      create_term_mapping pseudo_graph_pattern, search_param unless search_param.simple_mode?

      search = create_search search_param.query, pseudo_graph_pattern
      search.append_dialog search_param.user_id if search_param.user_id.present?

      SearchJob.perform_later search.search_id, search_param.user_id
      search.register_callback callback_url

      search.search_id
    end

    def create_term_mapping pseudo_graph_pattern, search_param
      TermMapping.create pseudo_graph_pattern:,
                         dataset_name: search_param.target,
                         mapping: search_param.mappings
    end

    def create_search query, pseudo_graph_pattern
      search = Search.new(query: query.presence || '',
                          pseudo_graph_pattern:)
      search.assign_id!
      search.be_referred!
      search
    end
  end
end
