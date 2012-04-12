class StopBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id)
    Box.find(box_id).stop!
  end
end
