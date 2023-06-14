# frozen_string_literal: true

# Dialog.
# A dialog is a sequence of natural language expressions.
class Dialog < ApplicationRecord
  has_many :natural_language_expressions, dependent: :destroy
  has_many :contextualized_natural_language_expressions, dependent: :destroy

  alias context natural_language_expressions

  def self.for user_id
    # Consider stopwords in the future.
    Dialog.find_or_create_by user_id:
  end

  def sentences_in depth
    context.order(:id).last(depth).pluck(:query)
  end
end
