# frozen_string_literal: true

# If user_id is specified, register it in the Dialog table.
class Dialog < ApplicationRecord
  belongs_to :search

  class << self
    # Get user dialog history
    def history user_id
      return [] unless user_id.present?

      where(user_id: user_id)
    end

    def queued_dialogs
      Dialog.group(:user_id).group(:search_id)
            .select('search_id, user_id, max(dialogs.created_at) as latest_created_at,
              count(dialogs.id) as dialog_count')
            .order(latest_created_at: :desc)
            .includes(search: :pseudo_graph_pattern)
    end
  end
end
