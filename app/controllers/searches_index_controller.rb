# frozen_string_literal: true

# A controller to show registered searches.
class SearchesIndexController < ActionController::Base
  # Show registered searches
  def index
    @searches = Search.queued_searches
    respond_to do |format|
      format.html
      format.json { render json: @searches }
    end
  end
end
