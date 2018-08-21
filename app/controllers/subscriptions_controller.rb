# frozen_string_literal: true

# A controller to register a new subscription to the query
class SubscriptionsController < ApplicationController
  # Register a new subscription to the query
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
