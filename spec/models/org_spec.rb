require 'spec_helper'

describe Org do
  it { should_not allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :permalink }
  it { should_not allow_mass_assignment_of :billing_email }

  describe "Validations" do
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

  describe "Callbacks" do
    context 'with spaces, commas and periods' do
      it "should pre-fill the permalink with a cleanedup org name" do
        org = build :org, name: 'Acme, Inc.'
        expect {
          org.save
        }.to change(org, :permalink).from(nil).to('acme-inc')
      end
    end

    context 'with slashes' do
      it "should pre-fill the permalink with a cleanedup org name" do
        org = build :org, name: 'Re/Code, Inc.'
        expect {
          org.save
        }.to change(org, :permalink).from(nil).to('re-code-inc')
      end
    end
  end
end
