require 'spec_helper'

describe Team do
  it { should_not allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :org  }

  describe 'Associations' do
    it { should belong_to :org }
    it { should have_many :team_memberships }
    it { should have_many(:members).through(:team_memberships) }
  end

  describe 'Validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :org_id }

    it { should validate_uniqueness_of(:name).scoped_to(:org_id) }
  end
end
