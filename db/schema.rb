# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_09_21_045527) do

  create_table "events", force: :cascade do |t|
    t.string "search_id", limit: 36, null: false
    t.string "event", null: false
    t.text "data", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event"], name: "index_events_on_event"
    t.index ["search_id"], name: "index_events_on_search_id"
  end

  create_table "searches", force: :cascade do |t|
    t.string "search_id", limit: 36, null: false
    t.string "query", default: "", null: false
    t.datetime "created_at", default: "-4712-01-01 00:00:00", null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "aborted_at"
    t.integer "read_timeout", default: 5, null: false
    t.integer "sparql_limit", default: 100, null: false
    t.integer "answer_limit", default: 10, null: false
    t.index ["search_id"], name: "index_searches_on_search_id", unique: true
  end

end
