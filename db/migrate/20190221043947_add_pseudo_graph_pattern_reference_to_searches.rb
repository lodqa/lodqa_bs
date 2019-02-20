class AddPseudoGraphPatternReferenceToSearches < ActiveRecord::Migration[5.2]
  def change
    add_reference :searches, :pseudo_graph_pattern, foreign_key: true
  end
end
