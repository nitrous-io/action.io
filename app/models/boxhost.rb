class Boxhost < ActiveRecord::Base
  attr_accessible :name

  belongs_to :owner, class_name: 'User'
  belongs_to :region
  belongs_to :boxhost_plan
  belongs_to :boxhost_provider_template

  has_many :boxes
  has_many :boxhost_key_pairs, dependent: :destroy

  validates :name, presence: true,
                   length: { in: (4..40) }
end
