class BoxTemplate < ActiveRecord::Base
  attr_accessible :name, :image, :description

  has_many :boxes, dependent: :nullify
end
