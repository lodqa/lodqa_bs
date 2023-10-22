# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2023_06_15_053041) do
  create_table "contextualized_natural_language_expressions", force: :cascade do |t|
    t.string "query"
    t.integer "dialog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dialog_id"], name: "index_contextualized_natural_language_expressions_on_dialog_id"
  end

  create_table "dialogs", force: :cascade do |t|
    t.string "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "event", null: false
    t.text "data", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "pseudo_graph_pattern_id"
    t.index ["event"], name: "index_events_on_event"
    t.index ["pseudo_graph_pattern_id"], name: "index_events_on_pseudo_graph_pattern_id"
  end

  create_table "natural_language_expressions", force: :cascade do |t|
    t.string "query"
    t.integer "dialog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dialog_id"], name: "index_natural_language_expressions_on_dialog_id"
  end

  create_table "pseudo_graph_patterns", force: :cascade do |t|
    t.text "pgp", null: false
    t.integer "read_timeout", default: 5, null: false
    t.integer "sparql_limit", default: 100, null: false
    t.integer "answer_limit", default: 10, null: false
    t.string "target", default: "", null: false
    t.boolean "private", default: false, null: false
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "aborted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "query"
  end

  create_table "searches", force: :cascade do |t|
    t.string "search_id", limit: 36, null: false
    t.datetime "created_at", precision: nil, default: "-4712-01-01 00:00:00", null: false
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "aborted_at", precision: nil
    t.integer "pseudo_graph_pattern_id"
    t.datetime "referred_at", precision: nil
    t.integer "contextualized_natural_language_expression_id"
    t.index ["contextualized_natural_language_expression_id"], name: "index_searches_on_contextualized_natural_language_expression_id"
    t.index ["pseudo_graph_pattern_id"], name: "index_searches_on_pseudo_graph_pattern_id"
    t.index ["search_id"], name: "index_searches_on_search_id", unique: true
  end

  create_table "term_mappings", force: :cascade do |t|
    t.integer "pseudo_graph_pattern_id", null: false
    t.string "dataset_name", null: false
    t.text "mapping", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["pseudo_graph_pattern_id"], name: "index_term_mappings_on_pseudo_graph_pattern_id"
  end

  add_foreign_key "contextualized_natural_language_expressions", "dialogs"
  add_foreign_key "events", "pseudo_graph_patterns"
  add_foreign_key "natural_language_expressions", "dialogs"
  add_foreign_key "searches", "contextualized_natural_language_expressions"
  add_foreign_key "searches", "pseudo_graph_patterns"
  add_foreign_key "term_mappings", "pseudo_graph_patterns"
end
