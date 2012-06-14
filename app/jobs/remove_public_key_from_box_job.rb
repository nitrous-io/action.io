class RemovePublicKeyFromBoxJob
  attr_accessor :box_id, :dummy_key

  def initialize(box_id, dummy_key)
    self.box_id = box_id
    self.dummy_key = dummy_key
  end

  def perform
    Box.find(self.box_id).remove_public_key(self.dummy_key)
  end
end
