require 'spec_helper'

describe BoxhostProviderTemplate do
  it { should allow_mass_assignment_of :provider }
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :config }
  it { should allow_mass_assignment_of :boxhost_plan_id }
  it { should allow_mass_assignment_of :location_id }

  it { should belong_to(:boxhost_plan) }
  it { should belong_to(:location) }

  it { should have_many(:boxhosts) }
end
