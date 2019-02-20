class RemoveSearchIdFromEvents < ActiveRecord::Migration[5.2]
  def change
    remove_column :events, :search_id
  end
end
