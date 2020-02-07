class CreateDialogs < ActiveRecord::Migration[6.0]
  def change
    create_table :dialogs do |t|
      t.string :user_id, null: false
      t.references :search, limit: 36, null: false

      t.timestamps
    end

    add_foreign_key :dialogs, :searches
  end
end
