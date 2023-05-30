# frozen_string_literal: true

# A controller to show registered searches.
class SearchesViewController < ApplicationController
  # Show registered searches
  def index
    DbConnection.using { @searches = Search.queued_searches }
    respond_to do |format|
      format.html
      format.json { render json: @searches }
    end
  end

  def show
    @search = Search.find(params[:id])
  end

  def destroy
    Search.find_by(id: params[:id]).pseudo_graph_pattern.destroy
    redirect_to searches_path, notice: I18n.t('delete_success')
  end
end
