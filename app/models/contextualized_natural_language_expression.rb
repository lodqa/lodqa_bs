# frozen_string_literal: true

class ContextualizedNaturalLanguageExpression < ApplicationRecord
  belongs_to :dialog
  has_one :search, dependent: :destroy
end
