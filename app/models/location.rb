class Location < ActiveRecord::Base
  US_WEST = 'us-west'
  US_EAST = 'us-east'
  EU_WEST = 'eu-west'
  SOUTH_AMERICA = 'sa'
  AP_NORTHEAST = 'ap-northeast'
  AP_SOUTHEAST = 'ap-southeast'
  OCEANIA = 'oceania'

  has_many :boxhosts
  has_many :boxhost_provider_templates

  attr_accessible :name, :description
end
