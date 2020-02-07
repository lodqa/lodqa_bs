class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :user_id, null: false
      t.references :search, limit: 36, null: false

      t.timestamps
    end

    add_foreign_key :users, :searches
  end
end
