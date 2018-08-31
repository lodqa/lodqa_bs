class RenameQueryToSearch < ActiveRecord::Migration[5.2]
  def change
    rename_table :queries, :searches
    rename_column :searches, :query_id, :search_id
    rename_column :searches, :statement, :query
    rename_column :searches, :queued_at, :created_at
    rename_column :events, :query_id, :search_id
  end
end
