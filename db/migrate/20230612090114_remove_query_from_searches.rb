class RemoveQueryFromSearches < ActiveRecord::Migration[7.0]
  def up
    remove_column :searches, :query
  end

  def down
    add_column :searches, :query, :string, default: "", null: false
  end
end
