class BoxTemplate < ActiveRecord::Base
  attr_accessible :name, :description, :runtime, :enabled, :admin

  has_many :boxes, dependent: :nullify

  scope :available_to_regular_users, -> { where('admin = ?', false) }
end
