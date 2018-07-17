class CreateAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :answers do |t|
      t.string :request_id, null: false, limit: 36
      t.string :uri,        null: false
      t.string :label,      null: false

      t.timestamps
    end

    add_index :answers, %i[request_id uri], unique: true
  end
end
