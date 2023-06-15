# frozen_string_literal: true

# Business logic about registering a search
module RegisterSearchService
  class << self
    # Register a search.
    # Start a new search job unless same search and pgp exists.
    # Call back only if same search or pgp exists.
    def register search_param
      if search_param.simple_mode?
        do_simple_mode search_param
      else
        do_export_mode search_param
      end
    end

    private

    def do_simple_mode search_param
      query = if search_param.user_id
                contextualize search_param.user_id, search_param.query
              else
                search_param.query
              end

      # Different natural language queries may result in the same pgp
      # even if the natural language queries are different,
      # for example, if the number of whitespace strings in
      # the natural language queries are different.
      pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern query
      duplicated_pgp = PseudoGraphPattern.equals_in pgp,
                                                    search_param.read_timeout,
                                                    search_param.sparql_limit,
                                                    search_param.answer_limit,
                                                    search_param.target

      if duplicated_pgp
        return start_callback_job_with duplicated_pgp.search,
                                       search_param.callback_url
      end

      pseudo_graph_pattern = PseudoGraphPattern.create(pgp:,
                                                       target: search_param.target,
                                                       read_timeout: search_param.read_timeout,
                                                       sparql_limit: search_param.sparql_limit,
                                                       answer_limit: search_param.answer_limit,
                                                       private: search_param.private,
                                                       query:)

      start_search_job pseudo_graph_pattern, search_param.callback_url
    end

    def do_export_mode search_param
      search = Search.equals_in search_param.read_timeout,
                                search_param.sparql_limit,
                                search_param.answer_limit,
                                search_param.target,
                                search_param.mappings

      return start_callback_job_with search, search_param.callback_url if search

      pseudo_graph_pattern = PseudoGraphPattern.create(pgp: search_param.pgp,
                                                       target: search_param.target,
                                                       read_timeout: search_param.read_timeout,
                                                       sparql_limit: search_param.sparql_limit,
                                                       answer_limit: search_param.answer_limit,
                                                       private: search_param.private)
      create_term_mapping pseudo_graph_pattern, search_param.target,
                          search_param.mappings

      start_search_job pseudo_graph_pattern, search_param.callback_url
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

    def create_term_mapping pseudo_graph_pattern, dataset_name, mapping
      TermMapping.create pseudo_graph_pattern:,
                         dataset_name:,
                         mapping:
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
