class DedicatedBoxhost < Boxhost
  module TYPES
    ALL = [
      TYPE_1X = '1x', # 512MB RAM.
      TYPE_2X = '2x',
      TYPE_4X = '4x',
      TYPE_8X = '8x',
      TYPE_16X = '16x',
      TYPE_32X = '32x',
    ]
  end

  attr_accessor :provision_webhook

  validates :region_id, presence: true, on: :update, if: :unprovisioned?
  validate :validate_region_unchanged, on: :update, unless: :unprovisioned?

  state_machine initial: :born do
    event(:enqueue_provision) { transition [:born, :failed]           => :provisioning  }
    event(:orphan)            { transition :provisioning              => :failed        }
    event(:enqueue_start)     { transition [:provisioning, :stopped]  => :starting      }
    event(:start)             { transition [:provisioning, :starting] => :running       }
    event(:enqueue_stop)      { transition :running                   => :stopping      }
    event(:stop)              { transition :stopping                  => :stopped       }
    event(:enqueue_restart)   { transition :running                   => :restarting    }
    event(:restart)           { transition :restarting                => :running       }
    event(:enqueue_terminate) { transition :stopped                   => :terminating   }
    event(:terminate)         { transition :terminating               => :terminated    }

    state :provisioning do
      validates_presence_of :region_id, :boxhost_plan_id
      validate :validate_provisionable
    end

    before_transition(on: :enqueue_provision) do |boxhost|
      boxhost.generate_key_pair
      provisioning = boxhost.provision_with_hostbuilder
      if !provisioning
        throw :halt
      end
    end

    after_transition on: :terminate, do: :update_termination_time!

    after_transition do: :push_boxhost_updated_message
  end

  def unprovisioned?
    self.state == 'born' || self.state == 'failed'
  end

  def dedicated?
    true
  end

  def hostbuilder
    return @hostbuilder if @hostbuilder
    return nil if self.boxhost_provider_template.nil?

    klass = self.boxhost_provider_template.hostbuilder_class
    return nil unless klass

    @hostbuilder = klass.new(self)
  end

  def provision_with_hostbuilder
    template = self.pick_template
    return false if !template

    self.boxhost_provider_template = template
    saved = self.save
    return false if !saved

    self.hostbuilder.create(self.provision_webhook)
  end

  def available_templates
    return [] if !self.region || !self.boxhost_plan

    templates = BoxhostProviderTemplate.where(
      region_id: self.region.id,
      boxhost_plan_id: self.boxhost_plan_id,
    )

    templates.select { |t| t.supported? }
  end

  def pick_template
    self.available_templates.sample
  end

  def generate_name
    if self.boxhost_plan
      "boxes-#{self.boxhost_plan.name}"
    else
      "boxes"
    end
  end

  def generate_key_pair
    key = GenerateSSHKey.generate
    self.boxhost_key_pairs.build.tap do |k|
      k.public_key = key.ssh_public_key
      k.private_key = key.private_key
      k.save!
    end
  end

  def public_keys
    self.boxhost_key_pairs.pluck(:public_key)
  end

  def push_boxhost_updated_message
    Shover.publish self.owner_id, 'aio:boxhost_updated', self.serialize_as_hash
  end

  def validate_region_unchanged
    if self.region_id_changed?
      errors.add :region_id, 'Region can no longer be changed.'
    end
  end

  def validate_provisionable
    return unless self.region && self.boxhost_plan

    unless available_templates.present?
      errors.add :region_id, 'Selected region is not currently available. Please pick a different region.'
    end
  end

  private
  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end
end
