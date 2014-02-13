class AddSourceSnapshotIdToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :source_snapshot_id, :integer
  end
end
