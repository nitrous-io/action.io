class Boxhost < ActiveRecord::Base
  module TYPES
    ALL = [
      TYPE_1X = '1x', # 512MB RAM.
      TYPE_2X = '2x',
      TYPE_4X = '4x',
      TYPE_8X = '8x',
      TYPE_16X = '16x',
      TYPE_32X = '32x',
    ]
  end

  attr_accessible :name

  belongs_to :owner, class_name: 'User'
  belongs_to :location
  belongs_to :boxhost_plan
  belongs_to :boxhost_provider_template


  def public_keys
    self.owner.public_keys.pluck(:key)
  end
end
