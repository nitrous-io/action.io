class BoxhostPlan < ActiveRecord::Base
  has_many :boxhost_provider_templates

  serialize :features, Array

  attr_accessible :name, :price, :interval, :box_limit, :display_order, :features
end
