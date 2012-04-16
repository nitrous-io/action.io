class BoxHost < ActiveRecord::Base
  belongs_to :region
  attr_accessible :region_id, :name, :host

  validates :name, presence: true, uniqueness: true
  validates_presence_of :region_id, :name, :host
end
