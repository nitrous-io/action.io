class AddonSubscription < ActiveRecord::Base
  include HTTParty
  format  :json

  extend EncryptedAttributes

  encrypted_attr_accessor :env_vars

  belongs_to  :box
  belongs_to  :addon

  state_machine initial: :unsubscribed do
    event(:enqueue_provision) { transition  :unsubscribed     => :provisioning }
    event(:enqueue_configure) { transition  :provisioning     => :configuring  }
    event(:configure)         { transition  :configuring      => :configured   }
    event(:enqueue_restart)   { transition  :configured       => :restarting   }
    event(:restart)           { transition  :restarting       => :subscribed   }

    # In the webhook for provision_box, call box.enqueue_start!
    before_transition(on: :enqueue_provision) do |box|
      Delayed::Job.enqueue(ProvisionAddonJob.new(self.id))
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
    # Check if the required_vars fulfills the addon's required vars,
    # If yes, then make a POST request to the addons API
    # If no, then how ah - raise error?
    result = self.class.post addon.production_base_url,
                             basic_auth: { username: addon.uid, password: addon.password },
                             query: { options: required_vars }

    self.resource_id = result['id']
    # Get the env vars returned by the request
    # save them in a database? as encrypted_env_vars
    self.env_vars = result['config'].to_json
    self.save!
    # once you save them, call enqueue_configure!
    # enqueue_configure! submits a Delayed::Job which intern calls AddonSubscription#configure
    self.enqueue_configure!
  end

  def configure
    # Make a request to coach #configure_box with the env vars,
    # Pass the addon_id to the request, so that coach returns it,
    # in the webhook callback, for the handler in aio:configured,
    # if addon_id is present, then do enqueue_restart!
  end

  def restart
    # restart the box, goto the IDE, in
    # in the webhook callback, for the handler in aio:configured,
    # if addon_id is present, then do restart! on addon_subscription
  end
end
