class DeleteSnapshotJob < Struct.new(:snapshot_id)
  def perform
    snapshot = Snapshot.find self.snapshot_id
    snapshot.box.coach.delete_snapshot snapshot
  end
end
