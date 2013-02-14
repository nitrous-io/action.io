require 'spec_helper'

describe Region do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :coach_uri }
  it { should allow_mass_assignment_of :box_server_uri }

  it { should have_many(:boxes).dependent(:nullify) }

  describe 'validations' do
    let!(:region) { create :region }

    it { should validate_presence_of :name }
    it { should validate_presence_of :description }

    it { should validate_uniqueness_of :name }
  end

  describe 'scopes' do
    describe '.enabled' do
      let!(:region1) { create :region, enabled: true }
      let!(:region2) { create :region, enabled: true }
      let!(:region3) { create :region }

      subject { Region.enabled.all }

      it { should == [region1, region2] }
    end
  end
end
