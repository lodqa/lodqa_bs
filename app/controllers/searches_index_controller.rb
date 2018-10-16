# frozen_string_literal: true

# A controller to show registered searches.
class SearchesIndexController < ActionController::Base
  # Show registered searches
  def index
    @searches = Search.at_today
                      .includes(:events)
                      .order created_at: :desc
    respond_to do |format|
      format.html
      format.json { render json: @searches }
    end
  end
end
