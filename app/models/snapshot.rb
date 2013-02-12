class Snapshot < ActiveRecord::Base
  attr_accessible :name, :description

  belongs_to :box
  belongs_to :owner, class_name: 'User'

  validates_presence_of :owner, on: :create
  validates :name, presence: true,
                   uniqueness: { scope: :owner_id },
                   length: { in: (4..40) },
                   format: { with: /\A[a-zA-Z][a-zA-Z0-9-]*[a-zA-Z0-9]\z/,
                             message: "Use a-z, 0-9, and hyphen(-), can't start with hyphen or digits, can't end with hyphen." }

  validates :box_id, presence: true

  #TODO validate box is owned by the user

end

# == Schema Information
#
# Table name: snapshots
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  public      :boolean
#  box_id      :integer
#  owner_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

