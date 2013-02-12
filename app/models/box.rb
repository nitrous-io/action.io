class Box < ActiveRecord::Base
  attr_accessible :name

  has_many :box_admins, dependent: :destroy
  has_many :key_pairs,  dependent: :destroy

  has_many :users, through: :box_admins
  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  delegate  :box_server_uri, to: :region

  validates_presence_of :owner, on: :create
  validates :name, presence: true,
                   uniqueness: { scope: :owner_id },
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validates :region_id, presence: true
  validates :box_template_id, presence: true

  scope :unterminated,  where('state <> ?', 'terminated')
  scope :running,       where('state = ?', 'running')

  before_save do
    name.downcase!
  end

  before_create do
    users << owner if owner && !users.include?(owner)
  end

  after_create do
    generate_key_pair
  end

  def coach
    @coach ||= Coach.new(self)
  end

  def push_box_updated_message
    users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:box_updated', self.serialize_as_hash)
    end
  end

  state_machine initial: :born do
    event(:orphan)            { transition  :provisioning            => :born         }
    event(:enqueue_provision) { transition  :born                    => :provisioning }

    event(:enqueue_start)     { transition [:provisioning, :stopped] => :starting     }
    event(:start)             { transition  :starting                => :running      }

    event(:enqueue_stop)      { transition  :running                 => :stopping     }
    event(:stop)              { transition  :stopping                => :stopped      }

    event(:enqueue_restart)   { transition  :running                 => :restarting   }
    event(:restart)           { transition  :restarting              => :running      }

    event(:enqueue_terminate) { transition  :stopped                 => :terminating  }
    event(:terminate)         { transition  :terminating             => :terminated   }

    # In the webhook for provision_box, call box.enqueue_start!
    before_transition(on: :enqueue_provision) { |box| Delayed::Job.enqueue(ProvisionBoxJob.new(box.id)) }
    # In the webhook for start_box, call box.start!
    before_transition(on: :enqueue_start)     { |box| Delayed::Job.enqueue(StartBoxJob.new(box.id))     }
    # In the webhook for stop_box, call box.stop!
    before_transition(on: :enqueue_stop)      { |box| Delayed::Job.enqueue(StopBoxJob.new(box.id))      }
    # In the webhook for restart_box, call box.restart!
    before_transition(on: :enqueue_restart)   { |box| Delayed::Job.enqueue(RestartBoxJob.new(box.id))     }
    # In the webhook for terminate_box, call box.terminate!
    before_transition(on: :enqueue_terminate) { |box| Delayed::Job.enqueue(TerminateBoxJob.new(box.id)) }

    after_transition on: :terminate, do: :update_termination_time

    after_transition do: :push_box_updated_message
  end

  def add_public_key(key_string)
    self.coach.add_public_key(key_string)
  end

  def remove_public_key(key_string)
    self.coach.remove_public_key(key_string)
  end

  def generate_key_pair
    key = GenerateSSHKey.generate
    self.key_pairs.build.tap do |k|
      k.public_key = key.ssh_public_key
      k.private_key = key.private_key
      k.save!
    end
  end

  def container_name
    "#{self.name}-#{self.id}"
  end

  private
  def update_termination_time
    self.update_attribute :terminated_at, Time.now
  end
end

# == Schema Information
#
# Table name: boxes
#
#  id              :integer          not null, primary key
#  name            :string(255)      not null
#  host            :string(255)
#  state           :string(255)      default("born"), not null
#  box_template_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  owner_id        :integer
#  region_id       :integer
#  port            :integer
#  terminated_at   :datetime
#

