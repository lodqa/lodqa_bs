class CreateDialogs < ActiveRecord::Migration[6.0]
  def change
    create_table :dialogs do |t|
      t.string :user_id, null: false
      t.references :search, null: false

      t.timestamps
    end

    add_foreign_key :dialogs, :searches
    add_index       :dialogs, [:user_id, :search_id], unique: true, name: 'index_dialogs_searches_on_user_id_and_search_id'
  end
end
