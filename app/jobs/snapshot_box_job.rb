class SnapshotBoxJob < Job
  attr_accessor :snapshot_id

  def initialize(snapshot_id)
    self.snapshot_id = snapshot_id
  end

  def perform
    snapshot = Snapshot.find(self.snapshot_id)
    snapshot.coach.snapshot_box(snapshot)
  end

  def self.submit_job(snapshot_id)
    Delayed::Job.enqueue(new(snapshot_id))
  end
end
