class AddMoreIndicesToBoxes < ActiveRecord::Migration
  def change
    add_index :boxes, :state
    add_index :boxes, :version
    add_index :boxes, [:owner_id, :state]
    add_index :boxes, [:touched_at, :state]
    add_index :boxes, [:last_heartbeat_tracked_at, :state]
  end
end
