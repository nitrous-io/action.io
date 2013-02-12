class BoxTemplate < ActiveRecord::Base
  attr_accessible :name, :description, :runtime, :enabled, :admin

  has_many :boxes, dependent: :nullify

  scope :available_to_regular_users,  where('admin = ?', false)
end

# == Schema Information
#
# Table name: box_templates
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  enabled     :boolean          default(FALSE), not null
#  runtime     :string(255)
#  admin       :boolean          default(FALSE), not null
#

