class Boxhost < ActiveRecord::Base
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

  attr_accessible :name

  belongs_to :owner, class_name: 'User'
  belongs_to :location
  belongs_to :boxhost_plan
  belongs_to :boxhost_provider_template

  has_many :boxhost_key_pairs, dependent: :destroy

  validates :name, presence: true,
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
  validates :location_id, presence: true, on: :update, if: :unprovisioned?
  validate :validate_location_unchanged, on: :update, unless: :unprovisioned?

  state_machine initial: :born do
    event(:enqueue_provision) { transition :born                      => :provisioning  }
    event(:enqueue_start)     { transition [:provisioning, :stopped]  => :starting      }
    event(:start)             { transition :starting                  => :running       }
    event(:enqueue_stop)      { transition :running                   => :stopping      }
    event(:stop)              { transition :stopping                  => :stopped       }
    event(:enqueue_restart)   { transition :running                   => :restarting    }
    event(:restart)           { transition :restarting                => :running       }
    event(:enqueue_terminate) { transition :stopped                   => :terminating   }
    event(:terminate)         { transition :terminating               => :terminated    }

    state :provisioning do
      validates_presence_of :location_id, :boxhost_plan_id
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
    self.state == 'born'
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

    self.hostbuilder.create
  end

  def available_templates
    return [] if !self.location || !self.boxhost_plan

    templates = BoxhostProviderTemplate.where(
      location_id: self.location.id,
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

  def validate_location_unchanged
    if self.location_id_changed?
      errors.add :location_id, 'Location can no longer be changed.'
    end
  end

  def validate_provisionable
    return unless self.location && self.boxhost_plan

    unless available_templates.present?
      errors.add :location_id, 'Selected location is not currently available. Please pick a different location.'
    end
  end

  private
  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end
end
