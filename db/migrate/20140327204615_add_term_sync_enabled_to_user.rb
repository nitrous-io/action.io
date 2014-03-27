class AddTermSyncEnabledToUser < ActiveRecord::Migration
  def change
    add_column :users, :term_sync_enabled, :boolean, default: false
  end
end
