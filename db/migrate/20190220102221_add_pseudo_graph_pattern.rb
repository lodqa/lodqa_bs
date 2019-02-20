class AddPseudoGraphPattern < ActiveRecord::Migration[5.2]
  def change
    create_table :pseudo_graph_patterns do |t|
      t.text :pgp,                            null: false
      t.integer "read_timeout", default: 5,   null: false
      t.integer "sparql_limit", default: 100, null: false
      t.integer "answer_limit", default: 10,  null: false
      t.string "target",        default: "",  null: false
      t.boolean "private", default: false, null: false
      t.datetime "started_at"
      t.datetime "finished_at"
      t.datetime "aborted_at"

      t.timestamps
    end
  end
end
