class AddPublicKeyToBoxJob
  attr_accessor :box_id, :key_string

  def initialize(box_id, key_string)
    self.box_id = box_id
    self.key_string = key_string
  end

  def perform
    Box.find(self.box_id).add_public_key(self.key_string)
  end
end
