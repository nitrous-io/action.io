class ProvisionBoxJob < Struct.new(:box_id)
  def perform
    box = Box.find(self.box_id)
    box.coach.provision_box
  end
end
