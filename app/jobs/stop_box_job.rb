class StopBoxJob < Job
  attr_accessor :box_id

  def initialize(box_id)
    self.box_id = box_id
  end

  def perform
    box = Box.find(self.box_id)
    box.coach.stop_box
  end
end
