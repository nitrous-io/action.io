class AddPendingReconfigurationToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :pending_reconfiguration, :boolean, default: false, null: false
  end
end
