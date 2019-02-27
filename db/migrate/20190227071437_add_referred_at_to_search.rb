class AddReferredAtToSearch < ActiveRecord::Migration[5.2]
  def change
    add_column :searches, :referred_at, :datetime
  end
end
