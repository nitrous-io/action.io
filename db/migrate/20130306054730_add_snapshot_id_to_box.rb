class AddSnapshotIdToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :snapshot_id, :integer, null: true
  end
end
