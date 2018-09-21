class AddCallbacksFromSearches < ActiveRecord::Migration[5.2]
  def change
    add_column :searches, :private, :boolean, null: false, default: false
  end
end
