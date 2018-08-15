# frozen_string_literal: true

# Receive a query and register a job to search query.
class QueriesController < ApplicationController
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  def create
    job = LodqaSearchJob.perform_later(*lodqa_search_params)
    Query.create query_id: job.job_id, statement: params[:query]
    render json: { query_id: job.job_id }
  end

  private

  def lodqa_search_params
    params.require(%i[start_search_callback_url finish_search_callback_url])
  end
end
