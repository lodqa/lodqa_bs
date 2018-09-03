# frozen_string_literal: true

# A controller to register a new subscription to the search
class SubscriptionsController < ApplicationController
  # Register a new subscription to the search
  def create
    search_id = params[:search_id]
    unless Search.at_today
                 .alive?
                 .exists? search_id: search_id
      return render json: { search_id: search_id },
                    status: :not_found
    end

    return render nothing: true, status: :bad_request unless valid_url? params[:callback_url]

    NotificationJob.perform_now search_id, params[:callback_url]
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
