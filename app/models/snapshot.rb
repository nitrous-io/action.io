class Snapshot < ActiveRecord::Base
  belongs_to :user
  belongs_to :box, inverse_of: :snapshots
  has_many :boxes, foreign_key: :source_snapshot_id, inverse_of: :source_snapshot

  attr_accessible :name
end
