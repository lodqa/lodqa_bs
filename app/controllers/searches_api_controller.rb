# frozen_string_literal: true

# A controller to register a new search.
class SearchesApiController < ActionController::API
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  # Show information about a registered search.
  def show
    render pretty_json: Search.find_by(search_id: params[:id]), except: :id
  end

  # Register a new search and run a new job to search the search.
  def create
    search_id = register Search.new search_attributes
    render json: to_hash(search_id)
  end

  private

  # Register a query.
  # return search_id if same query exists.
  def register search
    cache = Search.equals_in search

    return cache.search_id if cache

    job = SearchJob.perform_later search.start_search_callback_url,
                                  search.finish_search_callback_url
    search.search_id = job.job_id
    search.save!
    search.search_id
  end

  def search_attributes
    params.require(%i[
                     query
                     start_search_callback_url
                     finish_search_callback_url
                   ])
    params.permit(%i[
                    query
                    start_search_callback_url
                    finish_search_callback_url
                    read_timeout
                    sparql_limit
                    answer_limit
                  ])
  end

  def to_hash search_id
    {
      search_id: search_id,
      search_url: "#{ENV['LODQA']}/answer?search_id=#{search_id}"
    }
  end
end
