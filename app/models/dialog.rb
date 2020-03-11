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

    def user_dialogs user_id
      dialogs = Dialog.group(:search_id)
                      .where(user_id: user_id)
                      .select('search_id, max(dialogs.created_at) as latest_created_at,
                        count(dialogs.id) as total_count')
                      .order(latest_created_at: :desc)
                      .includes(:search)
      dialogs.map do |dialog|
        {
          latest_created_at: dialog.latest_created_at,
          query: dialog.search.query,
          total_count: dialog.total_count
        }
      end
    end
  end
end
