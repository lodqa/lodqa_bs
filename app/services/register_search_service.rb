# frozen_string_literal: true

# Business logic about registering a search
module RegisterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search and pgp exists.
    # Call back only if same search or pgp exists.
    def register search_param
      if search_param.simple_mode?
        NaturalLanguageSearch.new(search_param.user_id,
                                  search_param.query,
                                  search_param.read_timeout,
                                  search_param.sparql_limit,
                                  search_param.answer_limit,
                                  search_param.target,
                                  search_param.private,
                                  search_param.callback_url).run

      else
        do_export_mode search_param.pgp,
                       search_param.read_timeout,
                       search_param.sparql_limit,
                       search_param.answer_limit,
                       search_param.target,
                       search_param.mappings,
                       search_param.private,
                       search_param.callback_url
      end
    end

    private

    def do_export_mode pgp, read_timeout, sparql_limit, answer_limit, target, mappings, private,
                       callback_url
      search = Search.equals_in read_timeout,
                                sparql_limit,
                                answer_limit,
                                target,
                                mappings

      return start_callback_job_with search, callback_url if search

      pseudo_graph_pattern = PseudoGraphPattern.create(pgp:,
                                                       target:,
                                                       read_timeout:,
                                                       sparql_limit:,
                                                       answer_limit:,
                                                       private:)
      pseudo_graph_pattern.term_mappings.create dataset_name: target,
                                                mapping: mappings

      start_search_job pseudo_graph_pattern, callback_url
    end

    def contextualize user_id, query
      dialog = Dialog.with user_id
      dialog.natural_language_expressions.create!(query:)
      Contextualizer.new(dialog).contextualize.query
    end

    # Call back events about an exiting search.
    def start_callback_job_with search, callback_url
      CallbackEventsJob.perform_later search, callback_url
      search.search_id
    end

    # Start new job for new search.
    def start_search_job pseudo_graph_pattern, callback_url
      search = create_search pseudo_graph_pattern

      SearchJob.perform_later search.search_id
      search.register_callback callback_url

      search.search_id
    end

    def create_search pseudo_graph_pattern
      Search.create! pseudo_graph_pattern:,
                     search_id: SecureRandom.uuid,
                     referred_at: Time.now.utc
    end
  end
end
