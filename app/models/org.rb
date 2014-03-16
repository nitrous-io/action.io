class Org < ActiveRecord::Base
  has_many    :teams
  belongs_to  :owner, class_name: 'User'

  validates_presence_of :name, :permalink, :billing_email, :owner_id
  # Transfer validation errors of permalink to name because
  # we don't really expose the permalink as an editable
  # value for Users but want to make it unique
  validate do
    errors.add :name, 'has already been taken' unless Org.find_by_permalink(permalized_name).nil?
  end

  before_validation do
    self.permalink = permalized_name if self.permalink.blank?
  end

  after_create  :create_default_teams_and_memberships!

  protected
  def permalized_name
    self.name.to_s.downcase.gsub(/\W+/, ' ').squeeze.strip.gsub(/ /, '-')
  end

  def create_default_teams_and_memberships!
    org_owners_team = self.teams.new
    org_owners_team.name = Team::OWNERS_NAME
    org_owners_team.save!

    owner_membership = TeamMembership.new
    owner_membership.team_id = org_owners_team.id
    owner_membership.member_id = self.owner_id
    owner_membership.save!
  end
end
