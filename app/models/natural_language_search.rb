# frozen_string_literal: true

# Search by natural language query.
class NaturalLanguageSearch
  include CanStartSearch
  def initialize user_id, query, read_timeout, sparql_limit, answer_limit, targets, private,
                 callback_url
    @user_id = user_id
    @query = query
    @read_timeout = read_timeout
    @sparql_limit = sparql_limit
    @answer_limit = answer_limit
    @targets = targets
    @private = private
    @callback_url = callback_url
  end

  def run
    # Different natural language queries may result in the same pgp
    # even if the natural language queries are different,
    # for example, if the number of whitespace strings in
    # the natural language queries are different.
    duplicated_pgp = PseudoGraphPattern.equals_in pgp,
                                                  target,
                                                  @read_timeout,
                                                  @sparql_limit,
                                                  @answer_limit

    if duplicated_pgp
      return start_callback_job_with duplicated_pgp.search,
                                     @callback_url
    end

    pseudo_graph_pattern = PseudoGraphPattern.create(pgp:,
                                                     target:,
                                                     read_timeout: @read_timeout,
                                                     sparql_limit: @sparql_limit,
                                                     answer_limit: @answer_limit,
                                                     private: @private,
                                                     query: real_query)

    start_search_job pseudo_graph_pattern, @callback_url
  end

  private

  def pgp
    @pgp ||= Lodqa::Graphicator.produce_pseudo_graph_pattern real_query
  end

  def real_query
    @real_query ||= if @user_id
                      contextualize @user_id, @query
                    else
                      @query
                    end
  end

  def contextualize user_id, query
    dialog = Dialog.with user_id
    dialog.natural_language_expressions.create!(query:)
    Contextualizer.new(dialog).contextualize.query
  end
end
