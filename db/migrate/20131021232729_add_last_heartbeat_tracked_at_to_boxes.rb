class AddLastHeartbeatTrackedAtToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :last_heartbeat_tracked_at, :datetime
  end
end
