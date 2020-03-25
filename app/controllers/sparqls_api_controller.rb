# frozen_string_literal: true

# A controller to count of sparqls.
class SparqlsApiController < ActionController::API
  include UrlValidator
  before_action :require_callback, only: [:create]
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  # Register a new search and run a new job to search the search.
  def create
    sparqls_params = SparqlsParameter.new sparql_attributes
    return render json: sparqls_params.errors, status: :bad_request if sparqls_params.invalid?

    sparqls_count = SparqlsCountService.sparqls_count sparqls_params
    render pretty_json: to_hash(sparqls_count)
  end

  private

  def require_callback
    callback_urls = [
      params[:callback_url]
    ]
    invalid_urls = callback_urls.reject do |url|
      valid_url? url
    end
    render json: UrlValidator::MESSAGE, status: :bad_request unless invalid_urls.empty?
  end

  def sparql_attributes
    params.require(%i[callback_url])
    params.permit %i[
      pgp
      mappings
      endpoint_url
      endpoint_options
      graph_uri
      graph_finder_options
      callback_url
    ]
  end

  def to_hash sparqls_count
    { sparqls_count: sparqls_count }
  end
end
