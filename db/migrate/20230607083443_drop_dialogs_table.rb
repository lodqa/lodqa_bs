class DropDialogsTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :dialogs
  end

  def down
    create_table :dialogs do |t|
      t.string :user_id, null: false
      t.references :search, null: false

      t.timestamps
    end

    add_foreign_key :dialogs, :searches
  end
end
