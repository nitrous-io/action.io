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

  validates :name, presence: true, length: { in: (4..40) }
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

    before_transition(on: :enqueue_provision) do |boxhost|
      boxhost.generate_key_pair
    end

    after_transition on: :terminate, do: :update_termination_time!

    after_transition do: :push_boxhost_updated_message
  end

  def unprovisioned?
    self.state == 'born'
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

  private
  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end
end
