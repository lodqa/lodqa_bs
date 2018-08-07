# frozen_string_literal: true

class DropAnswersTable < ActiveRecord::Migration[5.2]
  def change
    drop_table :answers do |t|
      t.string :request_id, null: false, limit: 36
      t.string :uri,        null: false
      t.string :label,      null: false

      t.timestamps
      t.index %i[request_id uri], unique: true
    end
  end
end
