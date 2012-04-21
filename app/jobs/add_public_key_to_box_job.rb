class AddPublicKeyToBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id, key_string)
    Box.find(box_id).add_public_key(key_string)
  end
end
