class RemoveParamsFromSearches < ActiveRecord::Migration[5.2]
  def change
    remove_column :searches, :read_timeout
    remove_column :searches, :sparql_limit
    remove_column :searches, :answer_limit
    remove_column :searches, :target
    remove_column :searches, :private
  end
end
