# frozen_string_literal: true

# A controller to show registered dialogs.
class UserHistoriesController < ActionController::Base
  # Get dialogs for user_id
  def show
    dialogs = Dialog.user_dialogs(params[:id])
    render pretty_json: dialogs
  end
end
