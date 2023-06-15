# frozen_string_literal: true

# Dialog.
# A dialog is a sequence of natural language expressions.
class Dialog < ApplicationRecord
  has_many :natural_language_expressions, dependent: :destroy
  has_many :contextualized_natural_language_expressions, dependent: :destroy

  alias context natural_language_expressions

  def self.with user_id
    Dialog.where.not(
      id: NaturalLanguageExpression.where(query: 'Begin new search').select(:dialog_id)
    )
          .find_or_create_by user_id:
  end

  def sentences_in depth
    context.order(:id).last(depth).pluck(:query)
  end
end
