# frozen_string_literal: true

# A controller to show registered queries.
class QueriesIndexController < ActionController::Base
  # Show registered queries
  def index
    @queries = Query
               .where(queued_at: Date.today.all_day)
               .includes(:events)
               .order queued_at: :desc
    respond_to do |format|
      format.html
      format.json { render json: @queries }
    end
  end
end
