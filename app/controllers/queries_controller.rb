class QueriesController < ApplicationController
  def create
    LodqaSearchJob.perform_later params[:query]
  end
end
