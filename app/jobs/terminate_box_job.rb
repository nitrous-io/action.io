class TerminateBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id)
    Box.find(box_id).terminate!
  end
end
