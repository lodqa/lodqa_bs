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
    job = SearchJob.perform_later(*lodqa_search_params)
    Query.create query_id: job.job_id, statement: params[:query], queued_at: Time.now
    render json: { query_id: job.job_id }
  end

  private

  def lodqa_search_params
    params.require(%i[start_search_callback_url finish_search_callback_url])
  end
end
