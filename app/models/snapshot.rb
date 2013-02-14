class Snapshot < ActiveRecord::Base
  attr_accessible :name, :description

  belongs_to :box
  belongs_to :owner, class_name: 'User'

  validates_presence_of :owner, on: :create
  validates_presence_of :box, on: :create
  validates :name, presence: true,
                   uniqueness: { scope: :owner_id },
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
end
