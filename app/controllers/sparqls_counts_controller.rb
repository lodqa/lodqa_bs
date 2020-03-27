# frozen_string_literal: true

# A controller to count of sparqls.
class SparqlsCountsController < ActionController::API
  # show count of sparqls.
  def show
    sparqls_params = SparqlsParameter.new sparql_attributes

    sparqls_count = SparqlsCountService.sparqls_count sparqls_params
    render pretty_json: to_hash(sparqls_count)
  end

  private

  def sparql_attributes
    params.permit %i[
      pgp
      mappings
      endpoint_url
      endpoint_options
      graph_uri
      graph_finder_options
    ]
  end

  def to_hash sparqls_count
    { sparqls_count: sparqls_count }
  end
end
