require 'spec_helper'

describe Boxhost do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :ip }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :dedicated }
  it { should_not allow_mass_assignment_of :terminated_at }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :location_id }
  it { should_not allow_mass_assignment_of :boxhost_plan_id }
  it { should_not allow_mass_assignment_of :boxhost_provider_template_id }

  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:location) }
  it { should belong_to(:boxhost_plan) }
  it { should belong_to(:boxhost_provider_template) }

  it { should have_many(:boxhost_key_pairs).dependent(:destroy) }

  describe 'validations' do
    let!(:boxhost) { create :boxhost }

    it { should validate_presence_of(:name) }
    it { should ensure_length_of(:name).is_at_least(4).is_at_most(40) }

    it { should allow_value('super-secrud-project-69').for(:name) }
    it { should allow_value('supersecrudproject69').for(:name) }
    it { should_not allow_value('sup3r-s3cr@d-pr0j3ct-69').for(:name) }
    it { should_not allow_value('super_secrud_project_69').for(:name) }
    it { should_not allow_value('69-super-secrud-project').for(:name) }
    it { should_not allow_value('-super-secrud-project-69').for(:name) }
    it { should_not allow_value('super-secrud-project-69-').for(:name) }
    it { should_not allow_value('super secrud project 69').for(:name) }
    it { should_not allow_value('秘密おっぱい').for(:name) }
    it { should_not allow_value('秘密-おっぱい-69').for(:name) }
  end
end
