class Box < ActiveRecord::Base
  N2O_MIN_MEMORY_MB = "n2o_min_memory_mb".freeze
  N2O_MAX_MEMORY_MB = "n2o_max_memory_mb".freeze
  N2O_MIN_STORAGE_MB = "n2o_min_storage_mb".freeze
  N2O_MAX_STORAGE_MB = "n2o_max_storage_mb".freeze

  COLLABORATOR_EXISTS = "COLLABORATOR_EXISTS".freeze
  ADD_COLLABORATOR    = "ADD_COLLABORATOR".freeze
  INVITE_COLLABORATOR = "INVITE_COLLABORATOR".freeze
  INVALID_IDENTIFIER  = "INVALID_IDENTIFIER".freeze

  DANGLING_BOX_STATES = %w(provisioning born starting stopping restarting terminating).freeze

  attr_accessible :name, :memory, :storage

  has_many :box_users,              dependent: :destroy
  has_many :key_pairs,              dependent: :destroy
  has_many :collaboration_invites,  dependent: :destroy

  has_many :users, through: :box_users
  has_many :n2o_allocations, as: :resource

  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  delegate  :box_server_uri, to: :region

  validates_presence_of :owner_id, :region_id, :box_template_id, :memory, :storage

  validates :name, presence: true,
                   uniqueness: { scope: :owner_id },
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validate :check_available_n2o
  validate :region_availability_on_create
  validate :check_if_memory_is_within_limits
  validate :check_if_storage_is_within_limits

  scope :unterminated,  where('state <> ?', 'terminated')
  scope :running,       where(state: "running")
  scope :dangling,      where('state IN (?)', DANGLING_BOX_STATES)
  scope :touched_since, -> since_time { where('touched_at < ?', since_time) }
  scope :idle, -> since_time { running.touched_since(since_time) }

  before_validation do
    name.try(:downcase!)
    round_down_memory_and_storage
  end

  before_create do
    users << owner if owner && !users.include?(owner)
  end

  after_create do
    generate_key_pair
    allocate_n2o
  end

  def coach
    @coach ||= Coach.new(self)
  end

  delegate :change_specs, to: :coach

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

    after_transition on: :terminate, do: :update_termination_time!
    after_transition on: :terminate, do: :deallocate_n2o
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

  def collaborator_status(identifier)
    collaborator = User.where('username = :identifier OR email = :identifier',
                              identifier: identifier).first

    status = if collaborator.blank?
      identifier =~ NitrousIO::EMAIL_REGEX ? INVITE_COLLABORATOR : INVALID_IDENTIFIER
    else
      self.users.include?(collaborator) ? COLLABORATOR_EXISTS : ADD_COLLABORATOR
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

  def round_down_memory_and_storage
    min_memory_limit = KeyValue[N2O_MIN_MEMORY_MB] || 0
    min_storage_limit = KeyValue[N2O_MIN_STORAGE_MB] || 0

    self.memory  = [memory  / 128 * 128, min_memory_limit].max if memory.present?
    self.storage = [storage / 250 * 250, min_storage_limit].max if storage.present?
  end

  def n2o_cost
    price_of_128MB_memory  = KeyValue[N2oAllocation::N2O_128MB_MEMORY] || 0
    price_of_250MB_storage = KeyValue[N2oAllocation::N2O_250MB_STORAGE] || 0

    (memory / 128) * price_of_128MB_memory + (storage / 250) * price_of_250MB_storage
  end

  def check_available_n2o
    if owner.present?
      free_n2o = owner.free_n2o

      if n2o_cost.present? && (free_n2o < n2o_cost)
        errors.add :base, 'Not enough N2O'
      end
    end
  end

  def check_if_memory_is_within_limits
    min_memory_limit = KeyValue[N2O_MIN_MEMORY_MB]
    max_memory_limit = KeyValue[N2O_MAX_MEMORY_MB]

    if min_memory_limit.present? && max_memory_limit.present?
      if memory < min_memory_limit || memory > max_memory_limit
        errors.add :memory, "Requested memory is not within the approved limits"
      end
    end
  end

  def check_if_storage_is_within_limits
    min_storage_limit = KeyValue[N2O_MIN_STORAGE_MB]
    max_storage_limit = KeyValue[N2O_MAX_STORAGE_MB]

    if min_storage_limit.present? && max_storage_limit.present?
      if storage < min_storage_limit || storage > max_storage_limit
        errors.add :storage, "Requested storage is not within the approved limits"
      end
    end
  end

  def allocate_n2o
    cost = n2o_cost
    if cost > 0
      n2o_alloc = self.n2o_allocations.build
      n2o_alloc.user = owner
      n2o_alloc.kind = N2oAllocation::Kind::BOX_CREATION
      n2o_alloc.amount = n2o_cost
      n2o_alloc.save!
    end
  end

  def deallocate_n2o
    n2o_allocations.each(&:deallocate!)
  end

  private
  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end

  def notify_box_provisioning_failure
    Notifier.delay.box_provisioning_failed(self.id)
  end
end
