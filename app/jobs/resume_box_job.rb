class ResumeBoxJob
  attr_accessor :box_id

  def initialize(box_id)
    self.box_id = box_id
  end

  def perform
    Box.find(self.box_id).resume!
  end
end
