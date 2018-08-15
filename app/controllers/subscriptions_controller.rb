# frozen_string_literal: true

# To get old events of the query.
class SubscriptionsController < ApplicationController
  def create
    query_id = params[:query_id]
    unless Query.exists? query_id: query_id
      return render json: { query_id: query_id },
                    status: :not_found
    end

    NotificationJob.perform_later query_id, params[:callback_url]
  end
end
