# frozen_string_literal: true

# Contextualized natural language expression.
class ContextualizedNaturalLanguageExpression < ApplicationRecord
  belongs_to :dialog
  has_one :search, dependent: :destroy
end
