class AddTargetToSearch < ActiveRecord::Migration[5.2]
  def change
    add_column :searches, :target, :string, null: false, default: ''
  end
end
