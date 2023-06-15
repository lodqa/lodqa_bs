class AddQueryToPseudoGraphPatterns < ActiveRecord::Migration[7.0]
  def change
    add_column :pseudo_graph_patterns, :query, :string
  end
end
