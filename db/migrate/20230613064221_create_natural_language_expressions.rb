class CreateNaturalLanguageExpressions < ActiveRecord::Migration[7.0]
  def change
    create_table :natural_language_expressions do |t|
      t.string :query
      t.references :dialog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
