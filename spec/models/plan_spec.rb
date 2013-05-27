require 'spec_helper'

describe Plan do
  it { should have_many(:users).through(:subscriptions) }
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :active }
  it { should allow_mass_assignment_of :price_cents }
  it { should allow_mass_assignment_of :num_boxes }
  it { should allow_mass_assignment_of :ram }
  it { should allow_mass_assignment_of :disk_space }
  it { should allow_mass_assignment_of :ssh_access }
  it { should allow_mass_assignment_of :sleepless }
end
