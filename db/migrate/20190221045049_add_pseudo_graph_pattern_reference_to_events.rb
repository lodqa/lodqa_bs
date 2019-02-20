class AddPseudoGraphPatternReferenceToEvents < ActiveRecord::Migration[5.2]
  def change
    add_reference :events, :pseudo_graph_pattern, foreign_key: true
  end
end
