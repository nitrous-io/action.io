class StartBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id)
    Box.find(box_id).start!
  end
end
