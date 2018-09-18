# frozen_string_literal: true

# A controller to register a new search.
class SearchesApiController < ActionController::API
  include UrlValidator
  before_action :require_callback, only: [:create]
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  # Show information about a registered search.
  def show
    render pretty_json: Search.find_by!(search_id: params[:id]), except: :id
  end

  # Register a new search and run a new job to search the search.
  def create
    search_id = ReigsterSearchService.register search_attributes
    render pretty_json: to_hash(search_id)
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

  def search_attributes
    params.require(%i[query callback_url])
    params.tap do |p|
      p[:start_search_callback_url] = p[:callback_url]
      p[:finish_search_callback_url] = p[:callback_url]
    end
          .permit %i[
            query
            start_search_callback_url
            finish_search_callback_url
            read_timeout
            sparql_limit
            answer_limit
          ]
  end

  def to_hash search_id
    {
      search_id: search_id,
      resouce_url: search_url(search_id),
      subscribe_url: search_subscriptions_url(search_id)
    }
  end
end
