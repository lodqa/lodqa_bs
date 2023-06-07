# frozen_string_literal: true

# If user_id is specified, register it in the Dialog table.
class Dialog < ApplicationRecord
  belongs_to :search

  class << self
    def ransackable_attributes _auth_object = nil
      %w[user_id_start]
    end

    def ransackable_associations _auth_object = nil
      ['search']
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
                      .where(user_id:)
                      .select('search_id, max(dialogs.created_at) as latest_created_at,
                        count(dialogs.id) as total_count')
                      .order(latest_created_at: :desc)
                      .includes(:search)
      dialogs.map do |dialog|
        user_dialog dialog
      end
    end

    private

    def user_dialog dialog
      {
        search_id: dialog.search.search_id,
        latest_created_at: dialog.latest_created_at,
        query: dialog.search.query,
        total_count: dialog.total_count
      }
    end
  end
end
