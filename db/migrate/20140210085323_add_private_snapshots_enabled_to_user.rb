class AddPrivateSnapshotsEnabledToUser < ActiveRecord::Migration
  def change
    add_column :users, :private_snapshots_enabled, :boolean, default: false, null: false
  end
end
