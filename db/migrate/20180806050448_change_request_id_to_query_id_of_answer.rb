class ChangeRequestIdToQueryIdOfAnswer < ActiveRecord::Migration[5.2]
  def change
    rename_column :answers, :request_id, :query_id
  end
end
