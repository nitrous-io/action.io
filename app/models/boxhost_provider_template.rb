class BoxhostProviderTemplate < ActiveRecord::Base
  belongs_to :boxhost_plan
  belongs_to :location

  has_many :boxhosts

  attr_accessible :provider, :name, :config, :boxhost_plan_id, :location_id

  serialize :config, JSON
end
