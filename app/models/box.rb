class Box < ActiveRecord::Base
  attr_accessible :name, :region

  has_many :box_admins, dependent: :destroy
  has_many :users, through: :box_admins
  belongs_to :box_template
  belongs_to :owner, class_name: 'User'

  validates_presence_of :owner, if: lambda { |b| b.new_record? }
  validates :name,   presence: true, uniqueness: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/ }
  validates :region, presence: true, inclusion: { in: Settings.valid_regions }

  before_save do
    name.downcase!
  end

  before_create do
    users << owner if owner
  end
end
