class RemovePublicKeyFromBoxJob
  @queue = :box_control_jobs

  def self.perform(box_id, dummy_key)
    Box.find(box_id).remove_public_key(dummy_key)
  end
end
