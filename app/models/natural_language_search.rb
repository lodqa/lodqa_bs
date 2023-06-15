# frozen_string_literal: true

# Search by natural language query.
class NaturalLanguageSearch
  include CanStartSearch
  def initialize user_id, query, read_timeout, sparql_limit, answer_limit, target, private,
                 callback_url
    @user_id = user_id
    @query = query
    @read_timeout = read_timeout
    @sparql_limit = sparql_limit
    @answer_limit = answer_limit
    @target = target
    @private = private
    @callback_url = callback_url
  end

  def run
    query = if @user_id
              contextualize @user_id, @query
            else
              @query
            end

    # Different natural language queries may result in the same pgp
    # even if the natural language queries are different,
    # for example, if the number of whitespace strings in
    # the natural language queries are different.
    pgp = Lodqa::Graphicator.produce_pseudo_graph_pattern query
    duplicated_pgp = PseudoGraphPattern.equals_in pgp,
                                                  @read_timeout,
                                                  @sparql_limit,
                                                  @answer_limit,
                                                  @target

    if duplicated_pgp
      return start_callback_job_with duplicated_pgp.search,
                                     @callback_url
    end

    pseudo_graph_pattern = PseudoGraphPattern.create(pgp:,
                                                     target: @target,
                                                     read_timeout: @read_timeout,
                                                     sparql_limit: @sparql_limit,
                                                     answer_limit: @answer_limit,
                                                     private: @private,
                                                     query:)

    start_search_job pseudo_graph_pattern, @callback_url
  end

  private

  def contextualize user_id, query
    dialog = Dialog.with user_id
    dialog.natural_language_expressions.create!(query:)
    Contextualizer.new(dialog).contextualize.query
  end
end
