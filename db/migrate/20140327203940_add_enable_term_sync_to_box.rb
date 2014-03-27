class AddEnableTermSyncToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :enable_term_sync, :boolean, default: false
  end
end
