# frozen_string_literal: true

# If user_id is specified, register it in the Dialog table.
class Dialog < ApplicationRecord
  belongs_to :search

  # Get user dialog history
  def self.history user_id
    return [] unless user_id.present?

    where(user_id: user_id)
  end
end
