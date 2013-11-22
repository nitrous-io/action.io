class Box < ActiveRecord::Base
  BASE_CPU_SHARES = 512 # Hardcoded base CPU shares value from Boxer.

  N2O_MIN_MEMORY_MB = "n2o_min_memory_mb".freeze
  N2O_MAX_MEMORY_MB = "n2o_max_memory_mb".freeze
  N2O_MIN_STORAGE_MB = "n2o_min_storage_mb".freeze
  N2O_MAX_STORAGE_MB = "n2o_max_storage_mb".freeze

  COLLABORATOR_EXISTS = "COLLABORATOR_EXISTS".freeze
  ADD_COLLABORATOR    = "ADD_COLLABORATOR".freeze
  INVITE_COLLABORATOR = "INVITE_COLLABORATOR".freeze
  INVALID_IDENTIFIER  = "INVALID_IDENTIFIER".freeze

  DANGLING_BOX_STATES = %w(born provisioning starting stopping reconfiguring restarting terminating).freeze

  attr_accessible :name, :memory, :storage

  has_many :box_users,              dependent: :destroy
  has_many :key_pairs,              dependent: :destroy
  has_many :collaboration_invites,  dependent: :destroy
  has_many :box_limit_hit_events,   dependent: :destroy

  has_many :users, through: :box_users
  has_many :n2o_allocations, as: :resource

  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  delegate  :box_server_uri, to: :region

  validates_presence_of :owner_id, :region_id, :box_template_id, :memory, :storage, :cpu_multiplier

  validates :name, presence: true,
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validate :validate_unique_name
  validate :validate_free_n2o, if: :n2o_allocation_needed?
  validate :validate_region_availability
  validate :validate_memory_limit
  validate :validate_storage_limit

  scope :unterminated,  where('state <> ?', 'terminated')
  scope :running,       where(state: "running")
  scope :dangling,      where('state IN (?)', DANGLING_BOX_STATES)
  scope :touched_since, -> (since_time) { where('touched_at < ?', since_time) }
  scope :free_idle, -> do
    where(id: Box.select('boxes.id').
      joins('INNER JOIN users ON users.id = boxes.owner_id').
      joins('LEFT OUTER JOIN billing_profiles ON users.id = billing_profiles.user_id').
      joins('LEFT OUTER JOIN subscriptions ON billing_profiles.id = subscriptions.billing_profile_id').
      where("billing_profiles.id IS NULL OR (billing_profiles.id IS NOT NULL AND (subscriptions.state IS NULL OR (subscriptions.state <> 'active' AND subscriptions.state <> 'payment_due')))").
      where('boxes.touched_at < ?', (Time.now - Settings.idle_box_grace_period.seconds)))
  end

  before_validation do
    name.try :downcase!
    round_down_memory_and_storage
  end

  before_create do
    self.version ||= region.version
    users << owner if owner && !users.include?(owner)
  end

  after_create :generate_key_pair

  before_save do
    # Make RAM == swap if swap is not set.
    self.virtual_memory ||= self.memory

    @should_allocate_n2o = n2o_allocation_needed?
    # if it's a new record, force it to allocate n2o
    # otherwise calculate actual n2o_delta
    @n2o_delta = new_record? ? 1 : n2o_delta
    nil # prevent falsy returns
  end

  after_save :allocate_n2o!, if: ->{ @n2o_delta != 0 }

  def coach
    @coach ||= Coach.new(self)
  end

  def push_box_updated_message
    users.pluck('users.id').each do |user_id|
      Pusher["private-user-#{user_id}"].trigger('aio:box_updated', self.serialize_as_hash)
    end
  end

  def validate_unique_name
    relation = Box.where("name = ? AND owner_id = ? AND state != ?", self.name, self.owner_id, 'terminated')
    if self.persisted?
      relation = relation.where("id != ?", self.id)
    end

    if relation.exists?
      errors.add :name, :taken
    end
  end

  def validate_region_availability
    return unless self.new_record? && self.owner && self.region

    unless self.owner.admin? || self.region.can_create_boxes?
      errors.add :region_id, 'Selected region is not currently available. Retry with a different region.'
    end
  end

  def backend_available?
    !state?(:migrating) && self.region.enabled? && !self.region.down?
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

    event(:enqueue_reconfigure)    { transition  :running                   => :reconfiguring       }
    event(:reconfigure)            { transition  :reconfiguring             => :running             }

    event(:enqueue_terminate) { transition  :stopped                        => :terminating         }
    event(:terminate)         { transition  :terminating                    => :terminated          }

    event(:enqueue_migrate) { transition all                                => :migrating           }
    event(:migrate) { transition :migrating                                 => :stopped             }

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
    # In the webhook for reconfigure, call box.reconfigure!
    before_transition(on: :enqueue_reconfigure) do |box|
      box.coach.reconfigure({ memory: box.memory, disk_space: box.storage, virtual_memory: box.virtual_memory })
    end

    after_transition on: :terminate, do: :update_termination_time!
    after_transition on: :terminate, do: :deallocate_n2o!
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
      identifier =~ AIO::EMAIL_REGEX ? INVITE_COLLABORATOR : INVALID_IDENTIFIER
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

  def notify_collaborator(username, author)
    if collaborator = self.users.where('username = :username', username: username).first
      Notifier.delay.collaboration_notification(collaborator.id, author.username, self.name)
    end
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

  def validate_memory_limit
    min_memory_limit = KeyValue[N2O_MIN_MEMORY_MB]
    max_memory_limit = KeyValue[N2O_MAX_MEMORY_MB]

    if min_memory_limit.present? && max_memory_limit.present?
      if memory < min_memory_limit || memory > max_memory_limit
        errors.add :memory, "Requested memory is not within the approved limits"
      end
    end
  end

  def validate_storage_limit
    min_storage_limit = KeyValue[N2O_MIN_STORAGE_MB]
    max_storage_limit = KeyValue[N2O_MAX_STORAGE_MB]

    if min_storage_limit.present? && max_storage_limit.present?
      if storage < min_storage_limit || storage > max_storage_limit
        errors.add :storage, "Requested storage is not within the approved limits"
      end
    end
  end

  def n2o_allocation_needed?
    new_record? || (configuration_changed? && n2o_delta > 0)
  end

  def configuration_changed?
    %w(storage memory virtual_memory cpu_multiplier).any? { |c| changed_attributes.has_key?(c) }
  end

  def n2o_delta
    memory_delta, storage_delta = 0, 0

    if memory_changes = changes['memory']
      memory_delta = (memory_changes[1] - memory_changes[0]) / 128
    end

    if(storage_changes = changes['storage'])
      storage_delta = (storage_changes[1] - storage_changes[0]) / 250
    end

    (KeyValue[N2oAllocation::N2O_250MB_STORAGE].to_i * storage_delta) +
    (KeyValue[N2oAllocation::N2O_128MB_MEMORY].to_i * memory_delta)
  end

  def self.count_by_region(opts = {})
    query = Box.select("COUNT(boxes.region_id) AS boxes_count, regions.name AS region_name").
                joins("JOIN regions on regions.id = boxes.region_id").
                group("regions.id").
                order("COUNT(boxes.region_id) DESC")

    if (state = opts[:state]).present?
      query = query.where("boxes.state = ?", state)
    end

    query.inject({}) do |res, elem|
      res[elem['region_name']] = elem['boxes_count'].to_i
      res
    end
  end

  def self.count_by_template(opts = {})
    query = Box.select("COUNT(boxes.box_template_id) AS boxes_count, box_templates.name AS template_name").
                joins("JOIN box_templates on box_templates.id = boxes.box_template_id").
                group("box_templates.id").
                order("COUNT(boxes.box_template_id) DESC")

    if (state = opts[:state]).present?
      query = query.where("boxes.state = ?", state)
    end

    query.inject({}) do |res, elem|
      res[elem['template_name']] = elem['boxes_count'].to_i
      res
    end
  end

  def self.count_by_memory(opts = {})
    query = Box.select("COUNT(id) AS count, memory").
                group("memory").
                order("count DESC")

    if (state = opts[:state]).present?
      query = query.where("boxes.state = ?", state)
    end

    query.inject({}) do |res, elem|
      res[elem['memory'].to_i] = elem['count'].to_i
      res
    end
  end

  def self.count_by_storage(opts = {})
    query = Box.select("COUNT(id) AS count, storage").
                group("storage").
                order("count DESC")

    if (state = opts[:state]).present?
      query = query.where("boxes.state = ?", state)
    end

    query.inject({}) do |res, elem|
      res[elem['storage'].to_i] = elem['count'].to_i
      res
    end
  end

  def self.total_count
    { 'count' => Box.select("id").count }
  end

  def self.running_count
    { 'count' => Box.select("id").where("state = ?", 'running').count }
  end

  def self.unterminated_count
    { 'count' => Box.select("id").where("state <> ?", 'terminated').count }
  end

  def self.born_count
    { 'count' => Box.select("id").where("state = ?", 'born').count }
  end

  def self.provisioning_count
    { 'count' => Box.select("id").where("state = ?", 'provisioning').count }
  end

  def self.starting_count
    { 'count' => Box.select("id").where("state = ?", 'starting').count }
  end

  def self.stopping_count
    { 'count' => Box.select("id").where("state = ?", 'stopping').count }
  end

  def self.stopped_count
    { 'count' => Box.select("id").where("state = ?", 'stopped').count }
  end

  def self.terminating_count
    { 'count' => Box.select("id").where("state = ?", 'terminating').count }
  end

  def self.terminated_count
    { 'count' => Box.select("id").where("state = ?", 'terminated').count }
  end

  def self.restarting_count
    { 'count' => Box.select("id").where("state = ?", 'restarting').count }
  end

  def self.reconfiguring_count
    { 'count' => Box.select("id").where("state = ?", 'reconfiguring').count }
  end

  def self.failed_count
    { 'count' => Box.select("id").where("state = ?", 'failed').count }
  end

  def self.migrating_count
    { 'count' => Box.select("id").where("state = ?", 'migrating').count }
  end

  def self.version
    ENV['AIO_CURRENT_BOX_VERSION']
  end

  def start_migration
    enqueue_migrate!
    coach.migrate
  end

  def finish_migration
    self.migrate!
    update_attribute :version, "cersei"
  end

  def update_auth(username, password)
    username = nil if username.blank?
    password = nil if password.blank?

    self.auth_username = username
    self.auth_password = password
    self.save
    self.coach.update_auth
  end

  private
  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end

  def notify_box_provisioning_failure
    Notifier.delay.box_provisioning_failed(self.id)
  end

  def validate_free_n2o
    if owner.present?
      ActiveRecord::Base.transaction(requires_new: true) do
        deallocate_n2o!
        free_n2o = owner.reload.free_n2o

        if n2o_cost.present? && (free_n2o < n2o_cost)
          errors.add :base, 'Not enough N2O'
        end

        raise ActiveRecord::Rollback
      end
      owner.reload # rollback does not restore instance data
    end
  end

  def allocate_n2o!
    cost = n2o_cost

    if cost > 0
      deallocate_n2o!
      n2o_alloc = self.n2o_allocations.build
      n2o_alloc.user = owner
      n2o_alloc.kind = N2oAllocation::Kind::BOX_CREATION
      n2o_alloc.amount = n2o_cost
      n2o_alloc.save!
    end
  end

  def deallocate_n2o!
    n2o_allocations.allocated.each(&:deallocate!)
  end
end
