class AddEnableTermSyncToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :term_sync_enabled, :boolean, default: false
  end
end
