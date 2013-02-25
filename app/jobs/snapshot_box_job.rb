class SnapshotBoxJob
  attr_accessor :snapshot_id

  def initialize(snapshot_id)
    self.snapshot_id = snapshot_id
  end

  def perform
    snapshot = Snapshot.find(self.snapshot_id)
    snapshot.box.coach.snapshot_box snapshot
  end
end
