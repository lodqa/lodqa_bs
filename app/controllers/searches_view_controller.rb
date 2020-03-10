# frozen_string_literal: true

# A controller to show registered searches.
class SearchesViewController < ActionController::Base
  # Show registered searches
  def index
    DbConnection.using { @searches = Search.queued_searches }
    respond_to do |format|
      format.html
      format.json { render json: @searches }
    end
  end

  def destroy
    Search.find_by(id: params[:id]).pseudo_graph_pattern.destroy
    redirect_to searches_path, notice: 'Delete success'
  end

  def show
    @search = Search.find(params[:id])
    respond_to do |format|
      format.html
    end
  end
end
