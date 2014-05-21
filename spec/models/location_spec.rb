require 'spec_helper'

describe Location do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }

  it { should have_many(:boxhosts) }
  it { should have_many(:boxhost_provider_templates) }
end
