class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :query_id, limit: 36, null: false
      t.string :event,               null: false
      t.text :data,                  null: false

      t.timestamps
    end
    add_index :events, :query_id
    add_index :events, :event
  end
end
