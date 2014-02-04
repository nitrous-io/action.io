class Snapshot < ActiveRecord::Base
  belongs_to :user
  belongs_to :box, inverse_of: :snapshots
  has_many :boxes, foreign_key: :source_snapshot_id, inverse_of: :source_snapshot

  attr_accessible :name

  validates :name, presence: true,
                   length: { in: (1..54) }, # Allow box name max length + 14 characters (for default suffix "-YYYYMMDD-hhmm")
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9 -]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, hyphen(-), spaces, can't start with hyphen or digits, can't end with hyphen." }
end
