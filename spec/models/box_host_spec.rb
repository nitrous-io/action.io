require 'spec_helper'

describe BoxHost do
  it { should allow_mass_assignment_of :region_id }
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :host }

  it { should belong_to :region }

  describe 'validations' do
    let!(:box_host) { create :box_host }

    it { should validate_presence_of :region_id }
    it { should validate_presence_of :name }
    it { should validate_presence_of :host }
    it { should validate_uniqueness_of :name }
  end
end
