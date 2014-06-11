require 'spec_helper'

describe BoxhostPlan do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :price }
  it { should allow_mass_assignment_of :interval }
  it { should allow_mass_assignment_of :box_limit }
  it { should allow_mass_assignment_of :display_order }
  it { should allow_mass_assignment_of :features }

  it { should have_many(:boxhosts) }
  it { should have_many(:boxhost_provider_templates) }
end
