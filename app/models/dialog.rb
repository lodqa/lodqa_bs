# frozen_string_literal: true

# If user_id is specified, register it in the Dialog table.
class Dialog < ApplicationRecord
  belongs_to :search
end
