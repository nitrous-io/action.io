class AddonSubscription < ActiveRecord::Base
  class AddonSubscriptionError < RuntimeError; end

  include HTTParty
  format  :json

  extend EncryptedAttributes

  encrypted_attr_accessor :env_vars

  belongs_to  :box
  belongs_to  :addon

  state_machine initial: :unsubscribed do
    event(:enqueue_provision) { transition :unsubscribed => :provisioning }
    event(:finish_provision)  { transition :provisioning => :provisioned }
    event(:enqueue_deprovision) { transition :provisioned => :deprovisioning }
    event(:finish_deprovision) { transition :deprovisioning => :deprovisioned }
    event(:reprovision) { transition :deprovisioned => :provisioning }
    after_transition do: :push_addon_updated_message
  end

  def push_addon_updated_message
    box.users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:addon_updated', addon.serialize_as_hash)
    end
  end

  # As the process can be slow, this is best called in a delayed job
  def provision
    addon = self.addon
    box = self.box
    result = self.class.post addon.production_base_url,
                             basic_auth: { username: addon.uid, password: addon.password },
                             body: { nitrous_id: box.id }.to_json

    self.resource_id = result['id']
    config = result['config']
    self.env_vars = config.to_json
    if save! && box.coach.set_environment_variables(config)
      finish_provision!
    else
      raise AddonSubscriptionError
    end 
  end

  def deprovision
    addon = self.addon
    delete_url = "#{addon.production_base_url}/#{box.id}"
    box.coach.remove_environment_variables addon.config_vars

    response = self.class.delete delete_url,
      basic_auth: { username: addon.uid, password: addon.password }

    if response.success?
      self.resource_id = nil
      self.finish_deprovision
    else
      raise AddonSubscriptionError
    end
  end

  # because of the unique constraint for addon+box, when we receive a provision
  # request for a deprovisioned addon, we will reprovision that addon instead
  # of creating a new one
  def self.provision(addon, box)
    subscription = AddonSubscription.where(addon_id: addon.id, box_id: box.id).first
    if subscription.present?
      if subscription.state?(:deprovisioned)
        subscription.reprovision!
        ProvisionAddonJob.new(subscription.id).delay.perform
      end
      subscription
    else
      AddonSubscription.new.tap do |s|
        s.addon = addon
        s.box = box
        s.save!
        if s.persisted?
          s.enqueue_provision!
          ProvisionAddonJob.new(s.id).delay.perform
        end
      end
    end
  end

  def self.deprovision(subscription)
    if subscription.state?("provisioned")
      subscription.enqueue_deprovision!
      DeprovisionAddonJob.new(subscription.id).delay.perform
    else
      subscription.errors.add :state, "Not ready to be deprovisioned"
    end
    subscription
  end
end
