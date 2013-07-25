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
    after_transition do: :push_addon_updated_message
  end

  def push_addon_updated_message
    box.users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:addon_updated', addon.serialize_as_hash)
    end
  end

  # As the process can be slow, this is best called in a delayed job
  # FIXME : when post faill, should revert the state/rollback
  def provision
    enqueue_provision!
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
end
