class AddonSubscription < ActiveRecord::Base
  class AddonSubscriptionError < RuntimeError; end

  include HTTParty
  format  :json

  extend EncryptedAttributes

  encrypted_attr_accessor :env_vars

  belongs_to  :box
  belongs_to  :addon_plan

  COLORS = %w(RED BLUE).freeze
  LIMIT = COLORS.length
  validate :limit_reached, on: :create

  state_machine initial: :unsubscribed do
    event(:enqueue_provision) { transition :unsubscribed => :provisioning }
    event(:finish_provision)  { transition :provisioning => :provisioned }
    event(:enqueue_deprovision) { transition :provisioned => :deprovisioning }
    event(:finish_deprovision) { transition :deprovisioning => :deprovisioned }
    event(:reprovision) { transition :deprovisioned => :provisioning }
    after_transition do: :push_updated_message
  end

  def limit_reached
    if addon.subscriptions_for(box_id).count >= LIMIT
      errors.add :box_id, "cannot provision more than #{LIMIT} plans for #{addon.name}"
    end
  end

  def addon
    addon_plan.addon
  end

  def push_updated_message
    box.users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:addon_subscription_updated',
                                                self.serialize_as_hash)
    end
  end

  # As the process can be slow, this is best called in a delayed job
  def provision
    addon = self.addon
    box = self.box
    result = self.class.post addon.production_base_url,
                             basic_auth: { username: addon.uid, password: addon.password },
                             body: { nitrous_id: id, plan: addon_plan.name }.to_json

    self.resource_id = result['id']
    # add prefix to config
    config = {}
    result['config'].each { |key, val| config["#{color}_#{key}"] = val }
    self.env_vars = config.to_json
    if save! && box.coach.set_environment_variables(config)
      finish_provision!
    else
      raise AddonSubscriptionError
    end
  end

  # get the expected color of the addon. This depends on the limit beings
  # implemented correctly so color will not be duplicate
  def color
    COLORS[(addon.subscriptions_for(box_id).count % LIMIT) - 1]
  end

  def deprovision
    addon = self.addon
    delete_url = "#{addon.production_base_url}/#{resource_id}"
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
  def self.provision(addon_plan, box)
    subscription = AddonSubscription.new
    subscription.addon_plan = addon_plan
    subscription.box = box
    if subscription.save
      subscription.enqueue_provision!
      ProvisionAddonJob.new(subscription.id).delay.perform
    end
    subscription
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
