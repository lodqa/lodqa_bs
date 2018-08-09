class AddStatementToQueries < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :statement, :string, null: false, default: ''
  end
end
