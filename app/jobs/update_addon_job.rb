class UpdateAddonJob
  attr_accessor :addon_subscription_id, :env_vars

  def initialize(addon_subscription_id, env_vars = {})
    self.addon_subscription_id = addon_subscription_id
    self.env_vars = env_vars
  end

  def perform
    addon_subscription = AddonSubscription.find(self.addon_subscription_id)
    addon_subscription.update_addon!(env_vars)
  end
end
