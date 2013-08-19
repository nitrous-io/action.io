class RemovePublicKeyFromBoxJob < Job
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

  def self.submit_job(box_id, key)
    Delayed::Job.enqueue RemovePublicKeyFromBoxJob.new(box_id, key)
  end
end
