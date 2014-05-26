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

  it { should have_many(:key_pairs).dependent(:destroy) }
  end
end
