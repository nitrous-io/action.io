class TeamMembership < ActiveRecord::Base
  belongs_to :member, class_name: 'User'
  belongs_to :team

  validates_presence_of :team_id, :member_id
end
