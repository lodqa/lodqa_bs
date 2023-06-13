# frozen_string_literal: true

# Dialog.
# A dialog is a sequence of natural language expressions.
class Dialog < ApplicationRecord
  has_many :natural_language_expressions, dependent: :destroy
  has_many :contextualized_natural_language_expressions, dependent: :destroy

  def context = natural_language_expressions
end
