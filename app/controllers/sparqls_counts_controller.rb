# frozen_string_literal: true
require 'sparql_client/endpoint_temporary_error'

# A controller to count of sparqls.
class SparqlsCountsController < ActionController::API
  rescue_from SparqlClient::EndpointTemporaryError do
    render nothing: true, status: :bad_gateway
  end

  # show count of sparqls.
  def show
    sparqls_params = SparqlsParameter.new sparql_attributes

    sparqls_count = SparqlsCount.sparqls_count sparqls_params
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
