class RemovePublicKeyFromBoxJob
  attr_accessor :box_id
  attr_accessor :key

  def initialize(box_id, key)
    self.box_id = box_id
    self.key = key
  end

  def perform
    box = Box.find(self.box_id)
    box.coach.remove_public_key(key)
  end
end
