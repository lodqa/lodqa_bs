class ChangeEventsColumnReferench < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :events, :queries, column: :query_id, primary_key: :query_id
  end
end
