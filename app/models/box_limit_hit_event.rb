class BoxLimitHitEvent < ActiveRecord::Base
  MEMORY = "memory".freeze

  attr_accessible :box_id, :kind, :limit_hit_at, :logged_event_id

  validates_presence_of   :box_id, :kind, :limit_hit_at, :logged_event_id
  validates_uniqueness_of :logged_event_id
end
