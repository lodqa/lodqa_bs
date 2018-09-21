class RemoveCallbacksFromSearches < ActiveRecord::Migration[5.2]
  def change
    remove_column :searches, :start_search_callback_url
    remove_column :searches, :finish_search_callback_url
  end
end
