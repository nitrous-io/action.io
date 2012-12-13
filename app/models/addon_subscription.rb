class AddonSubscription < ActiveRecord::Base
  class AddonSubscriptionError < RuntimeError; end

  include HTTParty
  format  :json

  extend EncryptedAttributes

  encrypted_attr_accessor :env_vars

  belongs_to  :box
  belongs_to  :addon

  state_machine initial: :unsubscribed do
    event(:enqueue_provision)   { transition :unsubscribed   => :provisioning   }
    event(:enqueue_configure)   { transition :provisioning   => :configuring    }
    event(:configure)           { transition :configuring    => :configured     }
    event(:enqueue_subscribe)   { transition :configured     => :subscribing    }
    event(:subscribe)           { transition :subscribing    => :subscribed     }

    event(:enqueue_deprovision) { transition :subscribed     => :deprovisioning }
    event(:enqueue_deconfigure) { transition :deprovisioning => :deconfiguring  }
    event(:deconfigure)         { transition :deconfiguring  => :deconfigured   }
    event(:enqueue_unsubscribe) { transition :deconfigured   => :unsubscribing  }
    event(:unsubscribe)         { transition :unsubscribing  => :unsubscribed   }

    before_transition(on: :enqueue_provision) do |addon_subscription|
      Delayed::Job.enqueue(ProvisionAddonJob.new(addon_subscription.id, JSON.parse(addon_subscription.addon.required_vars)))
    end

    before_transition(on: :enqueue_configure) do |addon_subscription|
      Delayed::Job.enqueue(ConfigureAddonJob.new(addon_subscription.id))
    end

    before_transition(on: :enqueue_deprovision) do |addon_subscription|
      Delayed::Job.enqueue(DeprovisionAddonJob.new(addon_subscription.id))
    end

    before_transition(on: :enqueue_deconfigure) do |addon_subscription|
      Delayed::Job.enqueue(DeconfigureAddonJob.new(addon_subscription.id))
    end

    after_transition(on: [:enqueue_subscribe, :enqueue_unsubscribe]) do |addon_subscription|
      addon_subscription.box.enqueue_restart!
    end

    after_transition do: :push_addon_updated_message
  end

  def push_addon_updated_message
    box.users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:addon_updated', addon.serialize_as_hash)
    end
  end

  def provision_addon!(required_vars = {})
    addon = self.addon
    response = self.class.post addon.production_base_url,
    basic_auth: { username: addon.uid, password: addon.password },
    body: { options: required_vars }

    if response.response.is_a? Net::HTTPOK
      self.resource_id = response['id']
      self.env_vars = response['config'].to_json
      self.save!
      self.enqueue_configure!
    else
      raise AddonSubscriptionError, "Bad request"
    end
  end

  def deprovision_addon!
    addon = self.addon
    response = self.class.delete "#{addon.production_base_url}/#{self.resource_id}",
    basic_auth: { username: addon.uid, password: addon.password }

    if response.response.is_a? Net::HTTPOK
      self.resource_id = nil
      self.save!
      self.enqueue_deconfigure!
    else
      raise AddonSubscriptionError, "Bad request"
    end
  end

  def configure_addon!
    if self.box.coach.set_environment_variables(self.env_vars)
      self.configure!
      self.enqueue_subscribe!
    else
      raise AddonSubscriptionError, "env_vars: #{self.env_vars}"
    end
  end

  def deconfigure_addon!
    if self.box.coach.remove_environment_variables(self.env_vars)
      self.env_vars = ''
      self.save!
      self.deconfigure!
      self.enqueue_unsubscribe!
    else
      raise AddonSubscriptionError, "env_vars: #{self.env_vars}"
    end
  end
end
