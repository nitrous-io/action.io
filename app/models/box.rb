class Box < ActiveRecord::Base
  COLLABORATOR_EXISTS = "COLLABORATOR_EXISTS".freeze
  ADD_COLLABORATOR    = "ADD_COLLABORATOR".freeze
  INVITE_COLLABORATOR = "INVITE_COLLABORATOR".freeze

  DANGLING_BOX_STATES = %w(provisioning born starting stopping restarting terminating).freeze

  attr_accessible :name

  has_many :box_users,              dependent: :destroy
  has_many :key_pairs,              dependent: :destroy
  has_many :collaboration_invites,  dependent: :destroy

  has_many :users, through: :box_users

  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  delegate  :box_server_uri, to: :region

  validates_presence_of :owner, on: :create
  validates :name, presence: true,
                   uniqueness: { scope: :owner_id },
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validates :region_id, presence: true
  validates :box_template_id, presence: true
  validate  :region_availability_on_create

  scope :unterminated,  where('state <> ?', 'terminated')
  scope :running,       where(state: "running")
  scope :dangling,      where('state IN (?)', DANGLING_BOX_STATES)
  scope :touched_since, -> since_time { where('touched_at < ?', since_time) }
  scope :idle, -> since_time { running.touched_since(since_time) }

  before_validation do
    name.try(:downcase!)
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

  def region_availability_on_create
    return unless self.new_record? && self.owner && self.region

    unless self.owner.admin? || self.region.can_create_boxes?
      errors.add :region_id, 'Selected region is not currently available. Retry with a different region.'
    end
  end

  def backend_available?
    self.region.enabled? && !self.region.down?
  end

  state_machine initial: :born do
    event(:orphan)            { transition  :provisioning                   => :failed              }
    event(:enqueue_provision) { transition  [:born, :failed]                => :provisioning        }

    event(:enqueue_start)     { transition [:provisioning, :stopped]        => :starting            }
    event(:start)             { transition  :starting                       => :running             }

    event(:enqueue_stop)      { transition  :running                        => :stopping            }
    event(:stop)              { transition  :stopping                       => :stopped             }

    event(:enqueue_restart)   { transition  :running                        => :restarting          }
    event(:restart)           { transition  :restarting                     => :running             }

    event(:enqueue_terminate) { transition  :stopped                        => :terminating         }
    event(:terminate)         { transition  :terminating                    => :terminated          }

    # In the webhook for provision_box, call box.enqueue_start!
    before_transition(on: :enqueue_provision) { |box| box.coach.provision_box }
    # In the webhook for start_box, call box.start!
    before_transition(on: :enqueue_start)     { |box| box.coach.start_box     }
    # In the webhook for stop_box, call box.stop!
    before_transition(on: :enqueue_stop)      { |box| box.coach.stop_box      }
    # In the webhook for restart_box, call box.restart!
    before_transition(on: :enqueue_restart)   { |box| box.coach.restart_box   }
    # In the webhook for terminate_box, call box.terminate!
    before_transition(on: :enqueue_terminate) { |box| box.coach.terminate_box }

    after_transition on: :terminate, do: :update_termination_time

    after_transition on: :orphan, do: :notify_box_provisioning_failure

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

  def collaborators
    users.where 'box_users.user_id <> ?', owner_id
  end

  def pending_accepted_invites
    Invite.where(box_id: id).where("state != ?", "accepted")
  end

  def collaborator_status(identifier)
    collaborator = User.where('username = :identifier OR email = :identifier',
                              identifier: identifier).first

    status = if collaborator.blank?
      INVITE_COLLABORATOR
    elsif self.users.include?(collaborator)
      COLLABORATOR_EXISTS
    else
      ADD_COLLABORATOR
    end

    status
  end

  def add_collaborator(identifier)
    collaborator = User.where('username = :identifier OR email = :identifier',
                              identifier: identifier).first

    if collaborator && !self.users.include?(collaborator)
      self.users << collaborator
    end

    collaborator
  end

  def invite_collaborator(email)
    collaboration_invite = CollaborationInvite.new.tap do |ci|
      ci.email = email
      ci.box_id = self.id
    end

    collaboration_invite.save
    collaboration_invite
  end

  private
  def update_termination_time
    self.update_attribute :terminated_at, Time.now
  end

  def notify_box_provisioning_failure
    Notifier.delay.box_provisioning_failed(self.id)
  end
end
