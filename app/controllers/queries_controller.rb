# frozen_string_literal: true

# Receive a query and register a job to search query.
class QueriesController < ApplicationController
  rescue_from ActionController::ParameterMissing do
    render nothing: true, status: :bad_request
  end

  def create
    LodqaSearchJob.perform_later(*lodqa_search_params)
  end

  private

  def lodqa_search_params
    params.require(%i[query start_search_callback_url finish_search_callback_url])
  end
end
