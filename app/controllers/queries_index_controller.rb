# frozen_string_literal: true

# Receive a query and register a job to search query.
class QueriesIndexController < ActionController::Base
  def index
    @queries = Query.all.order queued_at: :desc
    respond_to do |format|
      format.html
      format.json { render json: @queries }
    end
  end
end
