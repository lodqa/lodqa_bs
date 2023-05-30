# frozen_string_literal: true

# A controller to register a new subscription to the search
class SubscriptionsController < ApplicationController
  include UrlValidator
  before_action :require_callback

  # Register a new subscription to the search
  def create
    # return render nothing: true, status: :bad_request unless valid_url? params[:callback_url]
    callback_url = params[:callback_url]

    search_id = params[:search_id]
    search = Search.alive?
                   .find_by(search_id:)
    search.be_referred!
    return render json: { search_id: }, status: :not_found unless search

    SubscribeJob.perform_later search, callback_url
  end

  private

  def require_callback
    render json: UrlValidator::MESSAGE, status: :bad_request unless valid_url? params[:callback_url]
  end
end
