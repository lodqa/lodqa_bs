class AddContextualizedNaturalLanguageExpressionToSearch < ActiveRecord::Migration[7.0]
  def change
    add_reference :searches, :contextualized_natural_language_expression, null: true, foreign_key: true
  end
end
