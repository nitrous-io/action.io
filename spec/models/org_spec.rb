require 'spec_helper'

describe Org do
  it { should_not allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :permalink }
  it { should_not allow_mass_assignment_of :billing_email }
  it { should_not allow_mass_assignment_of :owner_id }

  describe 'Associations' do
    it { should have_many :teams }
    it { should belong_to(:owner).class_name('User') }
  end

  describe 'Validations' do
    subject { create :org }

    it { should validate_presence_of :name }
    it { should validate_presence_of :billing_email }

    describe 'uniqueness on permalink' do
      it 'should enforce uniqueness on permalinks' do
        org1 = create :org, name: 'Acme, Inc.'
        org2 = build :org, name: 'Acme,   Inc'

        expect(org2).to_not be_valid
        expect(org2.error_on(:name)).to match_array ['has already been taken']
      end
    end
  end

  describe 'Callbacks' do
    context 'after create' do
      it 'should create a default team called "Owners"' do
        org = create :org, name: 'Acme, Inc.'
        expect(org.teams.count).to eql 1
        expect(org.teams.first.name).to eql 'Owners'
      end

      it 'adds the owner to the team named "Owners"' do
        org = create :org, name: 'Acme, Inc.'
        owners_team = org.teams.where(name: 'Owners').first
        expect(owners_team.members.count).to eql 1
        expect(owners_team.members).to match_array [org.owner]
      end
    end

    context 'before validation' do
      context 'with spaces, commas and periods' do
        it 'should pre-fill the permalink with a cleanedup org name' do
          org = build :org, name: 'Acme, Inc.'
          expect {
            org.save
          }.to change(org, :permalink).from(nil).to('acme-inc')
        end
      end

      context 'with slashes' do
        it 'should pre-fill the permalink with a cleanedup org name' do
          org = build :org, name: 'Re/Code, Inc.'
          expect {
            org.save
          }.to change(org, :permalink).from(nil).to('re-code-inc')
        end
      end
    end
  end
end
