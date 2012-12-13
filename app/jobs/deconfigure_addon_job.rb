class DeconfigureAddonJob
  attr_accessor :addon_subscription_id

  def initialize(addon_subscription_id)
    self.addon_subscription_id = addon_subscription_id
  end

  def perform
    addon_subscription = AddonSubscription.find(self.addon_subscription_id)
    addon_subscription.deconfigure_addon!
  end
end
