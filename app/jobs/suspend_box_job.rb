class SuspendBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id)
    Box.find(box_id).suspend!
  end
end
