class ProvisionAddonJob
  attr_accessor :addon_subscription_id, :required_vars

  def initialize(addon_subscription_id, required_vars = {})
    self.addon_subscription_id = addon_subscription_id
    self.required_vars = required_vars
  end

  def perform
    addon_subscription = AddonSubscription.find(self.addon_subscription_id)
    addon_subscription.provision_addon!(required_vars)
  end
end
