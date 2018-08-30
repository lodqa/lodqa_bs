class AddAttributesToQuery < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :read_timeout, :integer,              null: false, default: 5
    add_column :queries, :sparql_limit, :integer,              null: false, default: 100
    add_column :queries, :answer_limit, :integer,              null: false, default: 10
    add_column :queries, :start_search_callback_url, :string,  null: false, default: 'http://example.com/'
    add_column :queries, :finish_search_callback_url, :string, null: false, default: 'http://example.com/'
  end
end
