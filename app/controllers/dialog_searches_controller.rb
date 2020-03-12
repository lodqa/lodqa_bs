# frozen_string_literal: true

# A controller to show registered dialogs.
class DialogSearchesController < ActionController::Base
  # Get dialogs for user_id
  def show
    search = Search.dialog_search(params[:id])
    render pretty_json: search
  end
end
