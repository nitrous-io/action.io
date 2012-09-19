class Region < ActiveRecord::Base
  attr_accessible :name, :description

  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description
end
