# frozen_string_literal: true

# A controller to show registered searches.
class SearchesIndexController < ActionController::Base
  # Show registered searches
  def index
    @searches = Search.where(created_at: Date.today.all_day)
                      .includes(:events)
                      .order created_at: :desc
    pp @searches.to_sql
    respond_to do |format|
      format.html
      format.json { render json: @searches }
    end
  end
end
