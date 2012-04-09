class Box < ActiveRecord::Base
  attr_accessible :name, :region

  has_many :box_admins, dependent: :destroy
  has_many :users, through: :box_admins
  belongs_to :box_template

  validates :name,   presence: true
  validates :region, presence: true, inclusion: { in: Settings.valid_regions }
end
