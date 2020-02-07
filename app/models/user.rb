# frozen_string_literal: true

# If user_id is specified, register it in the User table.
class User < ApplicationRecord
  belongs_to :search
end
