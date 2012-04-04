require 'spec_helper'

describe Authentication do
  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :provider }
  it { should_not allow_mass_assignment_of :uid }
  it { should_not allow_mass_assignment_of :created_at }
  it { should_not allow_mass_assignment_of :updated_at }

  it { should belong_to :user }

  describe 'validations' do
    before { create(:authentication).should be_valid }

    it { should validate_presence_of :provider }
    it { should validate_presence_of :uid }
  end
end
