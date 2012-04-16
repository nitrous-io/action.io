require 'spec_helper'

describe Region do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :ami }
  it { should allow_mass_assignment_of :keypair }

  it { should have_many(:box_hosts).dependent(:destroy) }
  it { should have_many(:boxes).dependent(:nullify) }

  describe 'validations' do
    let!(:region) { create :region }

    it { should validate_presence_of :name }
    it { should validate_presence_of :description }
    it { should validate_presence_of :ami }
    it { should validate_presence_of :keypair }

    it { should validate_uniqueness_of :name }
  end

  describe 'JSON representation' do
    let!(:region) { create :region }

    it 'only contains id, name, and description fields' do
      region.as_json.keys.should =~ %w(id name description)
    end
  end
end
