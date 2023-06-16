# frozen_string_literal: true

# Natural language expression.
class NaturalLanguageExpression < ApplicationRecord
  STOP_SENTENCE = 'Begin new search'

  belongs_to :dialog

  scope :stop_sentence, -> { where query: STOP_SENTENCE }

  def stop_sentence?
    query == STOP_SENTENCE
  end
end
