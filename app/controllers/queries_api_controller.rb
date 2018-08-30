# frozen_string_literal: true

# A controller to register a new query.
class QueriesApiController < ActionController::API
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  # Show information about a registered query.
  def show
    render json: Query.find_by(query_id: params[:id]), except: :id
  end

  # Register a new query and run a new job to search the query.
  def create
    statement = params[:query]
    query_id = register statement
    render json: to_hash(query_id)
  end

  private

  # Register a statement.
  # return query_id if same statement exists.
  def register statement
    cache = Query.exists? statement

    return cache.query_id if cache

    job = SearchJob.perform_later(*lodqa_search_params)
    Query.add(job.job_id, statement).query_id
  end

  def lodqa_search_params
    params.require(%i[start_search_callback_url finish_search_callback_url])
  end

  def to_hash query_id
    {
      query_id: query_id,
      query_url: "#{ENV['LODQA']}/answer?query_id=#{query_id}"
    }
  end
end
