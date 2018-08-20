class AddStartedAtFinishedAtToQuery < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :queued_at, :datetime, null: false, default: DateTime.new
    add_column :queries, :started_at, :datetime
    add_column :queries, :finished_at, :datetime
  end
end
