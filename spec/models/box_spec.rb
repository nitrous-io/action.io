require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :region }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :status }
  it { should_not allow_mass_assignment_of :template_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:template) }

  describe 'validations' do
    subject { build :box }

    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region) }
    it { should allow_value(*Settings.valid_regions).for(:region) }
    it { should_not allow_value('china').for(:region) }
  end
end
