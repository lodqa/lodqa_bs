class CreateTermMappings < ActiveRecord::Migration[5.2]
  def change
    create_table :term_mappings do |t|
      t.references :pseudo_graph_pattern, null: false
      t.text :mapping, null: false

      t.timestamps
    end

    add_foreign_key :term_mappings, :pseudo_graph_patterns
  end
end
