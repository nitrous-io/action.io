class BoxhostProviderTemplate < ActiveRecord::Base
  belongs_to :boxhost_plan
  belongs_to :region

  has_many :boxhosts

  attr_accessible :provider, :name, :config, :boxhost_plan_id, :region_id

  serialize :config, JSON

  # Returns Hostbuilder class for this template.
  def hostbuilder_class
    @hostbuilder_class ||= Hostbuilder.by_name(self.provider)
  end

  # Returns true if this template has a Hostbuilder implementation.
  def supported?
    self.hostbuilder_class.present?
  end
end
