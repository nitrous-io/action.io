class ProvisionAddonJob < Struct.new(:addon_subscription_id)
  def perform
    addon_subscription = AddonSubscription.find(self.addon_subscription_id)
    addon_subscription.provision
  end
end
