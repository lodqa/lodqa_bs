# frozen_string_literal: true

# To get old events of the query.
class SubscriptionsController < ApplicationController
  def create
    unless Query.exists? query_id: params[:query_id]
      return render json: { query_id: params[:query_id] },
                    status: :not_found
    end

    NotificationJob.perform_later params[:callback_url],
                                  params[:query_id]
  end
end
