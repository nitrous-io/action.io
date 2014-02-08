class Snapshot < ActiveRecord::Base
  belongs_to :user
  belongs_to :box, inverse_of: :snapshots
  has_many :boxes, foreign_key: :source_snapshot_id, inverse_of: :source_snapshot

  attr_accessible :name

  validates_presence_of :box
  validates :name, presence: true,
                   length: { in: (1..54) }, # Allow box name max length + 14 characters (for default suffix "-YYYYMMDD-hhmm")
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9 -]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, hyphen(-), spaces, can't start with hyphen or digits, can't end with hyphen." }

  before_create :set_user

  # FIXME Need a better name for the initial state than "requested". Ugh writer's block.
  state_machine initial: :requested do
    event(:initiate)        { transition :requested => :initiated }
    event(:mark_completed)  { transition :initiated => :completed }
    event(:mark_failed)     { transition :initiated => :failed    }
    event(:enqueue_delete)  { transition :completed => :deleted   }

    before_transition(on: :initiate)      { |snapshot| snapshot.initiate_snapshot_job }
    after_transition(on: :mark_completed) { |snapshot| snapshot.update_attribute :completed_at, Time.now }
    after_transition(on: :enqueue_delete) { |snapshot| snapshot.delete_snapshot_job   }
    after_transition do: :push_snapshot_updated_message
  end

  scope :undeleted, -> { where('state <> ?', 'deleted') }
  scope :chronological_order, -> { order(:created_at).reverse_order }
  scope :recently_requested, -> { where(state: 'requested').chronological_order }
  scope :recently_initiated, -> { where(state: 'initiated').chronological_order }

  def self.most_recently_requested
    self.recently_requested.first
  end

  def self.most_recently_initiated
    self.recently_initiated.first
  end

  def coach
    box.coach
  end

  def initiate_snapshot_job
    SnapshotBoxJob.submit_job(self.id)
  end

  def delete_snapshot_job
    DeleteSnapshotJob.submit_job(self.id)
  end

  def push_snapshot_updated_message
    Shover.publish self.user.id, 'aio:snapshot_updated', self.serialize_as_hash
  end

  private
  def set_user
    self.user = self.box.owner
  end
end
