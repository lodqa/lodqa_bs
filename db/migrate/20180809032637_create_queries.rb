class CreateQueries < ActiveRecord::Migration[5.2]
  def change
    create_table :queries do |t|
      t.string :query_id, limit: 36, null: false
    end
    add_index :queries, :query_id, unique: true
  end
end
