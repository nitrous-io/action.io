require 'spec_helper'

describe BoxTemplate do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :runtime }
  it { should allow_mass_assignment_of :enabled }
  it { should allow_mass_assignment_of :admin }

  it { should have_many(:boxes).dependent(:nullify) }

  describe 'scopes' do
    let!(:box_template_1) { create :box_template }
    let!(:box_template_2) { create :box_template, admin: true }
    let!(:box_template_3) { create :box_template, admin: true }

    describe '.available_to_regular_users' do
      it "should return all boxes which are available to the user" do
        BoxTemplate.available_to_regular_users.to_a.should =~ [box_template_1]
      end
    end
  end
end
