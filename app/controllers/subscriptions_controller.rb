# frozen_string_literal: true

# To get old events of the query.
class SubscriptionsController < ApplicationController
  def create
    query_id = params[:query_id]
    unless Query.exists? query_id: query_id
      return render json: { query_id: query_id },
                    status: :not_found
    end

    return render nothing: true, status: :bad_request unless valid_url? params[:callback_url]

    NotificationJob.perform_now query_id, params[:callback_url]
  end

  private

  # see https://stackoverflow.com/a/9047226/1276969
  def valid_url? value
    uri = URI.parse value
    uri.is_a? URI::HTTP
  rescue URI::InvalidURIError
    false
  end
end
