# frozen_string_literal: true

require 'lodqa/graphicator'

# Bussiness logic about registering a serach
module ReigsterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search exists.
    # Call back only if same search exists.
    def register search_param
      dupulicate_search = Search.equals_in search_param

      return start_new_job_for search_param, search_param.callback_url unless dupulicate_search

      call_back_events_about dupulicate_search, search_param.callback_url
    end

    private

    # Start new job for new search.
    def start_new_job_for search_param, callback_url
      pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern search_param.query
      pseudo_graph_pattern = PseudoGraphPattern.create pgp: pgp,
                                      target: search_param.target,
                                      read_timeout: search_param.read_timeout,
                                      sparql_limit: search_param.sparql_limit,
                                      answer_limit: search_param.answer_limit,
                                      private: search_param.private

      search = Search.new query: search_param.query,
                          pseudo_graph_pattern: pseudo_graph_pattern
      search_id = search.assign_id!

      SearchJob.perform_later search_id
      LateCallbacks.add_for search, callback_url

      search.search_id
    end

    # Call back events about an exiting search.
    def call_back_events_about search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end
  end
end
