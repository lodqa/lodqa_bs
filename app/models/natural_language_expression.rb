# frozen_string_literal: true

# Natural language expression.
class NaturalLanguageExpression < ApplicationRecord
  belongs_to :dialog

  scope :stop_sentence, -> { where query: 'Begin new search' }
end
