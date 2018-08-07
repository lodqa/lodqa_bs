# frozen_string_literal: true

# To get old events of the query.
class EventsController < ApplicationController
  def index
    render json: Event.where(query_id: params[:query_id]).pluck(:data)
  end
end
