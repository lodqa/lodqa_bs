# frozen_string_literal: true

# A controller to show registered dialogs.
class DialogsViewController < ActionController::Base
  PER = 10

  # Show registered dialogs
  def index
    @query = Dialog.ransack(search_params)
    @dialogs = @query.result.queued_dialogs.page(params[:page]).per(PER)
  end

  private

  def search_params
    params.fetch(:q, {}).permit(
      :user_id_start
    )
  end
end
