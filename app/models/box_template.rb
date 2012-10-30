class BoxTemplate < ActiveRecord::Base
  attr_accessible :name, :image, :description, :runtime, :enabled

  has_many :boxes, dependent: :nullify
end
