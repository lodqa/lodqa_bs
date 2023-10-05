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
                                  search_param.targets,
                                  search_param.private,
                                  search_param.callback_url).run

      else
        ExpertSearch.new(search_param.pgp,
                         search_param.read_timeout,
                         search_param.sparql_limit,
                         search_param.answer_limit,
                         search_param.targets,
                         search_param.mappings,
                         search_param.private,
                         search_param.callback_url).run
      end
    end
  end
end
