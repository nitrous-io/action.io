class BoxTemplate < ActiveRecord::Base
  attr_accessible :name, :description, :runtime, :enabled

  has_many :boxes, dependent: :nullify
end
