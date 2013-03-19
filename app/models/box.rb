class Box < ActiveRecord::Base
  attr_accessible :name

  has_many :box_admins, dependent: :destroy
  has_many :key_pairs,  dependent: :destroy
  has_many :snapshots

  has_many :users, through: :box_admins
  belongs_to :box_template
  belongs_to :snapshot
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
  validate :presence_of_template_or_snapshot

  DANGLING_BOX_STATES = %w(provisioning born starting stopping restarting terminating).freeze
  ARCHIVABLE_BOX_STATES = %w(running stopped).freeze

  scope :unterminated,  where('state <> ?', 'terminated')
  scope :running,       where('state = ?', 'running')
  scope :dangling,      where('state IN (?)', DANGLING_BOX_STATES)

  def self.idle(since_time=nil)
    since_time ||= 1.week.ago
    Box.where('state IN (?)', ARCHIVABLE_BOX_STATES).
      where('touched_at < ?', since_time)
  end

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
    event(:enqueue_provision) { transition [:born, :archived]        => :provisioning }

    event(:enqueue_start)     { transition [:provisioning, :stopped] => :starting     }
    event(:start)             { transition  :starting                => :running      }

    event(:enqueue_stop)      { transition  :running                 => :stopping     }
    event(:stop)              { transition  :stopping                => :stopped      }

    event(:enqueue_restart)   { transition  :running                 => :restarting   }
    event(:restart)           { transition  :restarting              => :running      }

    event(:enqueue_terminate) { transition  :stopped                 => :terminating  }
    event(:terminate)         { transition  :terminating             => :terminated   }

    event(:enqueue_snapshot)  { transition [:running, :stopped]      => :snapshotting }
    event(:finish_snapshot)   { transition :snapshotting             => :running }

    event(:enqueue_restore)   { transition [:running, :stopped]      => :restoring }
    event(:finish_restore)    { transition :restoring                => :running }

    event(:enqueue_archive)   { transition :stopped                  => :archiving }
    event(:archived)          { transition :archiving                => :archived }

    # In the webhook for provision_box, call box.enqueue_start!
    before_transition(on: :enqueue_provision) { |box| Delayed::Job.enqueue(ProvisionBoxJob.new(box.id)) }
    # In the webhook for start_box, call box.start!
    before_transition(on: :enqueue_start)     { |box| Delayed::Job.enqueue(StartBoxJob.new(box.id)) }
    # In the webhook for stop_box, call box.stop!
    before_transition(on: :enqueue_stop)      { |box| Delayed::Job.enqueue(StopBoxJob.new(box.id)) }
    # In the webhook for restart_box, call box.restart!
    before_transition(on: :enqueue_restart)   { |box| Delayed::Job.enqueue(RestartBoxJob.new(box.id)) }
    # In the webhook for terminate_box, call box.terminate!
    before_transition(on: :enqueue_terminate) { |box| Delayed::Job.enqueue(TerminateBoxJob.new(box.id)) }
    # In the webhook for archive_box, call box.finish_archive!
    before_transition(on: :enqueue_archive) { |box| Delayed::Job.enqueue(ArchiveBoxJob.new(box.id)) }

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

  def create_snapshot(attrs)
    snapshot = self.snapshots.build name: attrs[:name],
      description: attrs[:description]
    snapshot.public = attrs[:public] || false
    snapshot.save
    if snapshot.valid?
      snapshot.start
      self.enqueue_snapshot!
    end
    snapshot
  end

  def restore_snapshot(snapshot_id)
    snapshot = self.snapshots.find snapshot_id
    self.coach.restore_snapshot snapshot
    self.enqueue_restore!
  end

  def finish_archived!(snapshot_url)
    snapshot = self.snapshots.build name: "#{self.name}-#{Time.now.to_i}"
    snapshot.url = snapshot_url
    snapshot.state = :snapshotted
    snapshot.save
    self.archived!
  end

  def enqueue_unarchive!
    self.snapshot = self.snapshots.last
    if self.snapshot.present?
      self.enqueue_provision!
    else
      self.errors.add :base, "Missing archive."
    end
  end

  private
  def presence_of_template_or_snapshot
    unless (self.box_template_id.present? || self.snapshot_id.present?)
      self.errors.add :base, "Missing box template or snapshot"
    end
  end

  def update_termination_time
    self.update_attribute :terminated_at, Time.now
  end
end
