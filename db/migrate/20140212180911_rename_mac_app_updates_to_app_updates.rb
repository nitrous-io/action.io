class RenameMacAppUpdatesToAppUpdates < ActiveRecord::Migration
  def change
    rename_table :mac_app_updates, :app_updates
  end
end
