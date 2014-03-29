class Team < ActiveRecord::Base
  belongs_to  :org
  has_many    :team_memberships
  has_many    :members, through: :team_memberships

  validates_presence_of :name, :org_id
  validates_uniqueness_of :name, scope: :org_id

  OWNERS_NAME = 'Owners'
end
