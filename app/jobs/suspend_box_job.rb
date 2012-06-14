class SuspendBoxJob
  attr_accessor :box_id

  def initialize(box_id)
    self.box_id = box_id
  end

  def perform
    Box.find(box_id).suspend!
  end
end
