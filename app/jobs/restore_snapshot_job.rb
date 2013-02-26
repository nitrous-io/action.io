class RestoreSnapshotJob < Struct.new(:box_id, :snapshot_id)
  def perform
    box = Box.find self.box_id
    box.restore_snapshot self.snapshot_id
  end
end
