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
end
