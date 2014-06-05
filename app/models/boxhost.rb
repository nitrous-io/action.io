class Boxhost < ActiveRecord::Base
  attr_accessible :name

  belongs_to :owner, class_name: 'User'
  belongs_to :location
  belongs_to :boxhost_plan
  belongs_to :boxhost_provider_template

  has_many :boxhost_key_pairs, dependent: :destroy

  validates :name, presence: true,
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use only a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }
end
