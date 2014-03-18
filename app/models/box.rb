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

  DANGLING_BOX_STATES = %w(born provisioning starting stopping restarting terminating).freeze

  attr_accessible :name, :memory, :storage
  attr_accessor :state_triggered_by

  belongs_to :source_snapshot, class_name: 'Snapshot', inverse_of: :boxes
  has_many :snapshots, dependent: :nullify, inverse_of: :box
  has_many :clones, class_name: 'Box', through: :snapshots, source: :boxes

  has_many :repositories, dependent: :destroy, inverse_of: :box

  has_many :box_users,              dependent: :destroy
  has_many :key_pairs,              dependent: :destroy
  has_many :collaboration_invites,  dependent: :destroy
  has_many :box_limit_hit_events,   dependent: :destroy

  has_many :users, through: :box_users
  has_many :n2o_allocations, as: :resource

  has_many :box_transitions # no dependent destroy as we may want to debug destroyed boxes

  belongs_to :box_template
  belongs_to :owner, class_name: 'User'
  belongs_to :region

  delegate :box_server_uri, to: :region
  delegate :update_premium, to: :coach

  validates_presence_of :owner_id, :region_id, :memory, :storage, :cpu_multiplier

  validates :name, presence: true,
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validates :custom_domain, uniqueness: { allow_nil: true,  message: 'is already being used' }

  validate :validate_unique_name
  validate :validate_free_n2o, if: :n2o_allocation_needed?
  validate :validate_region_availability
  validate :validate_memory_limit
  validate :validate_storage_limit
  validate :validate_presence_of_box_template_or_source_snapshot
  validate :validate_source_snapshot_size, on: :create
  validate :validate_custom_domain

  scope :unterminated,  -> { where('state <> ?', 'terminated') }
  scope :running,       -> { where(state: 'running') }
  scope :dangling,      -> { where('state IN (?)', DANGLING_BOX_STATES) }
  scope :unpaid, -> do
    where(id: Box.select('boxes.id').
      joins('INNER JOIN users ON users.id = boxes.owner_id').
      joins('LEFT OUTER JOIN subscriptions ON users.id = subscriptions.user_id').
      where('subscriptions.id IS NULL OR (subscriptions.id IS NOT NULL AND subscriptions.state IN (?) OR subscriptions.payment_due = ?)', ['pending', 'canceled'], true))
  end
  scope :free_idle, -> do
    unpaid.
      where(state: 'running').
      where('boxes.touched_at IS NULL OR boxes.touched_at < ?', Time.now - Settings.idle_box_grace_period.to_i.seconds)
  end
  scope :untouched_since, ->(time) do
    where('boxes.touched_at < :since OR (boxes.touched_at IS NULL AND boxes.created_at < :since)', since: time)
  end
  scope :due_for_termination_notice, -> do
    unpaid.
      untouched_since(Settings.box_termination_grace_period_in_days.to_i.days.ago).
      where(state: 'stopped', termination_notice_sent_at: nil)
  end
  scope :eligible_for_termination, -> do
    unpaid.
      untouched_since(Settings.box_termination_grace_period_in_days.to_i.days.ago).
      where(state: 'stopped').
      where('boxes.termination_notice_sent_at IS NOT NULL').
      where('boxes.termination_notice_sent_at < ?', 5.days.ago)
  end

  before_validation do
    name.try :downcase!
    round_down_memory_and_storage
  end

  before_create do
    self.version ||= region.version
    users << owner if owner && !users.include?(owner)
  end

  before_save do
    # Make RAM == swap if swap is not set.
    self.virtual_memory ||= (self.memory / 2)

    @should_allocate_n2o = n2o_allocation_needed?
    # if it's a new record, force it to allocate n2o
    # otherwise calculate actual n2o_delta
    @n2o_delta = new_record? ? 1 : n2o_delta
    nil # prevent falsy returns
  end

  after_save :allocate_n2o!, if: ->{ @n2o_delta != 0 }
  after_save :wipe_custom_domain!, unless: :custom_domains_allowed?

  def coach
    @coach ||= Coach.new(self)
  end

  def push_box_updated_message
    payload = self.serialize_as_hash
    users.pluck('users.id').each do |user_id|
      Shover.publish user_id, 'aio:box_updated', payload
      Pusher["private-user-#{user_id}"].trigger('aio:box_updated', payload)
    end
  end

  def backend_available?
    !state?(:migrating) && self.region.enabled? && !self.region.down?
  end

  # The state machine interface should be private i.e. you should not call
  # do_start, etc... unless you have very good reason to (to skip additional
  # callbacks when the event finishes for example).
  #
  # Use the wrapper around this events instead i.e (start without do).
  #
  # When adding a new state, you need to add transition event to the wrapper methods as well.
  state_machine initial: :born do
    event(:do_orphan)              { transition  :provisioning             => :failed        }
    event(:do_enqueue_provision)   { transition  [:born, :failed]          => :provisioning  }

    event(:do_enqueue_start)       { transition [:provisioning, :stopped]  => :starting      }
    event(:do_start)               { transition  :starting                 => :running       }

    event(:do_enqueue_stop)        { transition  :running                  => :stopping      }
    event(:do_stop)                { transition  :stopping                 => :stopped       }

    event(:do_enqueue_restart)     { transition  :running                  => :restarting    }
    event(:do_restart)             { transition  :restarting               => :running       }

    event(:do_enqueue_snapshot)    { transition :stopped                   => :snapshotting  }
    event(:do_snapshot)            { transition :snapshotting              => :stopped       }

    event(:do_enqueue_terminate)   { transition  :stopped                  => :terminating   }
    event(:do_terminate)           { transition  :terminating              => :terminated    }

    event(:do_enqueue_migrate)     { transition all                        => :migrating     }
    event(:do_migrate)             { transition :migrating                 => :stopped       }

    # In the webhook for provision_box, call box.enqueue_start!
    before_transition(on: :do_enqueue_provision) do |box|
      box.generate_key_pair
      box.coach.provision_box
    end
    # In the webhook for start_box, call box.start!
    before_transition(on: :do_enqueue_start)       { |box| box.coach.start_box(box.expected_specs_for_coach) }
    # In the webhook for stop_box, call box.stop!
    before_transition(on: :do_enqueue_stop)        { |box| box.coach.stop_box }
    # In the webhook for restart_box, call box.restart!
    before_transition(on: :do_enqueue_restart)     { |box| box.coach.restart_box(box.expected_specs_for_coach) }
    # In the webhook for terminate_box, call box.terminate!
    before_transition(on: :do_enqueue_terminate)   { |box| box.coach.terminate_box }

    after_transition on: :do_start, do: :clear_force_shutdown_time!
    after_transition on: :do_start, do: :set_touched_at!
    after_transition on: :do_terminate, do: :update_termination_time!
    after_transition on: :do_terminate, do: :deallocate_n2o!
    after_transition on: :do_orphan, do: :notify_box_provisioning_failure
  end

  # redefine all events transitioning method with a new method that call
  # Box#push_box_updated_message after transition to the new state.
  #
  # Use Box#transition_triggered when you want to transition to a new state, e.g.
  #   transition_triggered(:orphan!, 'system')
  #   transition_triggered(:enqueue_reconfigure!, current_user)
  # So that the entity triggering the transition will be recorded
  [
    :orphan, :enqueue_provision,
    :enqueue_start, :start,
    :enqueue_stop, :stop,
    :enqueue_restart, :restart,
    :enqueue_snapshot, :snapshot,
    :enqueue_terminate, :terminate,
    :enqueue_migrate, :migrate
  ].each do |event|
    define_method event do
      record_transition(event) do
        result = self.send "do_#{event}"
        if result
          self.push_box_updated_message
        end
        result
      end
    end

    define_method "#{event}!" do
      record_transition(event) do
        self.send "do_#{event}!"
        self.push_box_updated_message
      end
    end
  end

  def record_transition(event, &block)
    transition = box_transitions.build do |bt|
      bt.event = event
      bt.from_state = self.state
      bt.to_state = self.state # updated after block call
    end
    case triggered_by = self.state_triggered_by
    when User
      transition.set_user(triggered_by)
    when String
      transition.triggered_by = triggered_by
    else # default triggered_by
      Rails.logger.warn("State transition #{event} without triggered_by")
    end
    self.state_triggered_by = nil
    transition.save!
    begin
      result = block.call
    rescue => e
      raise e
    ensure
      transition.update_column(:to_state, self.state) if !changed?
    end
    result
  end

  def transition_triggered(event, triggered_by)
    self.state_triggered_by = triggered_by
    self.send(event)
  end

  def create_snapshot(name)
    snapshot = self.snapshots.build(name: name)
    snapshot.public = false
    snapshot.manual = true # Hardcoded until we support automated snapshots.
    if self.enqueue_snapshot && snapshot.save
      snapshot.initiate!
    end
    snapshot
  end

  def complete_snapshot(snapshot_id, attributes={})
    snapshot = self.snapshots.find_by_id(snapshot_id)
    if snapshot && snapshot.initiated?
      snapshot.url = attributes[:url]
      snapshot.size = attributes[:size]
      snapshot.mark_completed!
      self.snapshot!
      return snapshot
    end
    false
  end

  def fail_snapshot(snapshot_id)
    snapshot = self.snapshots.find_by_id(snapshot_id)
    if snapshot && snapshot.initiated?
      snapshot.mark_failed!
      self.snapshot!
      return snapshot
    end
    false
  end

  def snapshottable?
    self.stopped?
  end

  def repository_to_clone
    self.repositories.uncloned.order(:created_at).last
  end

  def repository_being_cloned(clone_url)
    self.repositories.find_by(state: 'cloning', clone_url: clone_url)
  end

  def add_public_key(key_string)
    self.coach.add_public_key(key_string)
  end

  def remove_public_key(key_string)
    self.coach.remove_public_key(key_string)
  end

  def enqueue_reconfigure!
    coach.reconfigure(expected_specs_for_coach)
    self.push_box_updated_message
  end

  def start_migration
    transition_triggered(:enqueue_migrate!, 'system')
    coach.migrate
  end

  def finish_migration
    transition_triggered(:migrate!, 'system')
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

  def update_custom_domain(custom_domain)
    if custom_domain.present?
      host = extract_host(custom_domain)
      if host
        custom_domain = host
      end
    else
      custom_domain = nil # do not store empty string for custom domain
    end
    self.custom_domain = Sanitize.clean(custom_domain)

    result = self.save
    return false if !result
    self.coach.update_custom_domain
  end

  # To be triggered when custom_domains_allowed? is no longer true (owner
  # subscription/plan change, etc).  Technically there may be some lag between
  # when owner subscription/plan changes and this is called, but boxes are
  # saved often enough that the lag should be negligible in practice.
  def wipe_custom_domain!
    update_custom_domain '' if self.custom_domain.present?
  end

  def generate_key_pair
    key = GenerateSSHKey.generate
    self.key_pairs.build.tap do |k|
      k.public_key = key.ssh_public_key
      k.private_key = key.private_key
      k.save!
    end
  end

  # Returns a box's public keys. This includes keys we generate for it as well as
  # keys uploaded by the user.
  def public_keys
    self.key_pairs.pluck(:public_key) + self.owner.public_keys.pluck(:key)
  end

  def container_name
    "#{self.name}-#{self.id}"
  end

  def force_shutdown?
    self.force_shutdown_at.present? && self.stopped?
  end

  def expected_specs_for_coach
    {
      memory: memory,
      disk_space: storage,
      virtual_memory: expected_virtual_memory,
      cpu_shares: expected_cpu_multiplier * BASE_CPU_SHARES
    }
  end

  def expected_cpu_multiplier
    owner.active_plan.try(:cpu_multiplier) || 1
  end

  def expected_virtual_memory
    ((owner.active_plan.try(:vmem_multiplier) || 0.5) * memory).to_i
  end

  def requires_downgrade?
    expected_cpu_multiplier < cpu_multiplier || expected_virtual_memory < virtual_memory
  end

  def requires_upgrade?
    expected_cpu_multiplier > cpu_multiplier || expected_virtual_memory > virtual_memory
  end

  def cpu_shares=(new_cpu_shares)
    if new_cpu_shares && new_cpu_shares.respond_to?(:to_i)
      self.cpu_multiplier = new_cpu_shares.to_i / BASE_CPU_SHARES
    end
    self.cpu_multiplier = 1 if self.cpu_multiplier < 1
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

  def validate_presence_of_box_template_or_source_snapshot
    if self.box_template_id.blank? && self.source_snapshot_id.blank?
      self.errors.add :base, 'Pick a box template or snapshot.'
    end
  end

  # If a source_snapshot is given, make sure its size is smaller than that of
  # the box's storage.
  def validate_source_snapshot_size
    if self.source_snapshot
      if self.storage < self.source_snapshot.size
        self.errors.add :base, "Snapshot requires box to have at least #{self.source_snapshot.size} MB storage."
      end
    end
  end

  def validate_custom_domain
    return if self.custom_domain.blank?
    self.errors.add :custom_domain, "is invalid" if extract_host(custom_domain).nil?
  end

  # Returns the host of a domain name, or nil if input is invalid
  def extract_host(domain_name)
    uri = domain_name.match(/^https?:\/\//) ? domain_name : "http://#{domain_name}"
    begin
      URI.parse(uri).host
    rescue URI::InvalidURIError
      nil
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

  # Returns states in which the box requires a restart for any new specs to
  # take effect.
  # These states DO NOT require a restart because the box will have to go
  # through an enqueue_start event (which will downgrade it) to get to a
  # running state:
  #   born/orphan/provisioning/failed/stopping/stopped/terminating/terminated/migrating
  def self.states_requiring_restart
    %w(starting running restarting)
  end

  def self.find_all_requiring_restart(owner_id)
    self.where(owner_id: owner_id).where(state: states_requiring_restart)
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

  def self.count_by_group(group_name, opts = {})
    query = nil

    query = case group_name
    when 'region_name'
      Box.select("COUNT(boxes.region_id) AS count, regions.name AS region_name").
          joins("JOIN regions on regions.id = boxes.region_id").
          group("regions.id").
          order("COUNT(boxes.region_id) DESC")
    when 'runtime'
      Box.select("COUNT(boxes.box_template_id) AS count, box_templates.runtime AS runtime").
          joins("JOIN box_templates on box_templates.id = boxes.box_template_id").
          group("box_templates.id").
          order("COUNT(boxes.box_template_id) DESC")
    when 'memory'
      Box.select("COUNT(id) AS count, memory").
          group("memory").
          order("count DESC")
    when 'storage'
      Box.select("COUNT(id) AS count, storage").
          group("storage").
          order("count DESC")
    end

    if (state = opts[:state]).present?
      query = query.where("boxes.state = ?", state)
    end

    if (region_name = opts[:region_name]).present?
      query = query.joins("JOIN regions on regions.id = boxes.region_id").
                    where("regions.name = ?", region_name)
    end

    if(runtime = opts[:runtime])
      query = query.joins("JOIN box_templates on box_templates.id = boxes.box_template_id").
                    where("box_templates.runtime = ?", runtime)
    end

    { 'count' => query.inject({}) { |res, e| res[e[group_name]] = e['count'].to_i; res } }
  end

  def self.count_by(opts = {})
    query = Box.select("boxes.*")

    if (state = opts[:state]).present?
      if state == 'unterminated'
        query = query.where("boxes.state <> ?", 'terminated')
      elsif state == 'dangling'
        query = query.where("boxes.state IN (?)", Box::DANGLING_BOX_STATES)
      else
        query = query.where("boxes.state = ?", state)
      end
    end

    if(region_name = opts[:region_name]).present?
      query = query.joins("JOIN regions on regions.id = boxes.region_id").
                    where("regions.name = ?", region_name)
    end

    if(runtime = opts[:runtime])
      query = query.joins("JOIN box_templates on box_templates.id = boxes.box_template_id").
                    where("box_templates.runtime = ?", runtime)
    end

    { 'count' => query.count }
  end

  def self.version
    ENV['AIO_CURRENT_BOX_VERSION']
  end

  def premium?
    !!self.owner.active_plan
  end

  def custom_domains_allowed?
    plan = self.try(:owner).try(:active_plan)
    plan.present? && plan.has_feature?(Plan::FEATURE_CUSTOM_DOMAINS)
  end

  private
  def clear_force_shutdown_time!
    self.update_attribute :force_shutdown_at, nil if self.force_shutdown_at
  end

  def set_touched_at!
    self.update_attribute :touched_at, Time.now
  end

  def update_termination_time!
    self.update_attribute :terminated_at, Time.now
  end

  def notify_box_provisioning_failure
    Notifier.delay.box_provisioning_failed(self.id)
  end

  def validate_free_n2o
    if owner.present?
      User.with_advisory_lock("user-n2o-#{owner.id}") do
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
