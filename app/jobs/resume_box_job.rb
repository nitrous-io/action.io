class ResumeBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id)
    Box.find(box_id).resume!
  end
end
