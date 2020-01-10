class InitSchema < ActiveRecord::Migration[5.2]
  def up
    create_table "events" do |t|
      t.string "event", null: false
      t.text "data", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "pseudo_graph_pattern_id"
      t.index ["event"], name: "index_events_on_event"
      t.index ["pseudo_graph_pattern_id"], name: "index_events_on_pseudo_graph_pattern_id"
    end
    create_table "pseudo_graph_patterns" do |t|
      t.text "pgp", null: false
      t.integer "read_timeout", default: 5, null: false
      t.integer "sparql_limit", default: 100, null: false
      t.integer "answer_limit", default: 10, null: false
      t.string "target", default: "", null: false
      t.boolean "private", default: false, null: false
      t.datetime "started_at"
      t.datetime "finished_at"
      t.datetime "aborted_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    create_table "searches" do |t|
      t.string "search_id", limit: 36, null: false
      t.string "query", default: "", null: false
      t.datetime "created_at", default: "-4712-01-01 00:00:00", null: false
      t.datetime "started_at"
      t.datetime "finished_at"
      t.datetime "aborted_at"
      t.integer "pseudo_graph_pattern_id"
      t.datetime "referred_at"
      t.index ["pseudo_graph_pattern_id"], name: "index_searches_on_pseudo_graph_pattern_id"
      t.index ["search_id"], name: "index_searches_on_search_id", unique: true
    end

    add_foreign_key "events", "pseudo_graph_patterns"
    add_foreign_key "searches", "pseudo_graph_patterns"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
