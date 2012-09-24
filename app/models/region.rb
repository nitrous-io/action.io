class Region < ActiveRecord::Base
  attr_accessible :name, :description, :coach_uri, :box_server_uri

  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description
end
