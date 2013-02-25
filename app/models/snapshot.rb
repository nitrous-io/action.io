class Snapshot < ActiveRecord::Base
  attr_accessible :name, :description

  belongs_to :box
  belongs_to :owner, class_name: 'User'

  validates_presence_of :box, on: :create
  validates :name, presence: true,
    uniqueness: { scope: :owner_id },
    length: { in: (4..40) },
    format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
              message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
  validate :validate_snapshot_creation_ability
  before_create :set_owner

  state_machine initial: :new do
    event(:start) { transition :new => :snapshotting }
    event(:finish_snapshot) { transition :snapshotting => :snapshotted }

    before_transition(on: :start) { |snapshot| Delayed::Job.enqueue(SnapshotBoxJob.new(snapshot.id)) }
    after_transition do: :push_snapshot_updated_message
  end

  def finish(url)
    self.url = url
    self.finish_snapshot!
  end

  def validate_snapshot_creation_ability
    if ENV['DISABLE_SNAPSHOT_CREATION'] == 'true' && !self.box.owner.admin?
      self.errors.add :base, 'Snapshot creation is temporarily disallowed. Please try again later.'
    end
  end

  def set_owner
    self.owner = self.box.owner
  end

  def push_snapshot_updated_message
    Pusher["private-user-#{self.owner_id}"].trigger('aio:snapshot_updated', self.serialize_as_hash)
  end
end
