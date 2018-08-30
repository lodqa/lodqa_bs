class AddAbortedAtToQuery < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :aborted_at, :datetime
  end
end
