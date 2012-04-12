class ProvisionBoxJob
  @queue = :box_provisioning_jobs

  def self.perform(box_id)
    box = Box.find(box_id)
    box.provision!
    box.start!
  end
end
