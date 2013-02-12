class Region < ActiveRecord::Base
  attr_accessible :name, :description, :coach_uri, :box_server_uri

  has_many :boxes, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates_presence_of :description

  scope :enabled, where(enabled: true).order(:id)
end

# == Schema Information
#
# Table name: regions
#
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  description    :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  enabled        :boolean          default(FALSE), not null
#  box_server_uri :string(255)
#  coach_uri      :string(255)
#

