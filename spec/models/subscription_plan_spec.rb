require 'spec_helper'

describe SubscriptionPlan do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :price }
  it { should allow_mass_assignment_of :display_order }
  it { should allow_mass_assignment_of :features }
  it { should allow_mass_assignment_of :highlight }
  it { should allow_mass_assignment_of :interval }
  it { should allow_mass_assignment_of :stripe_id }
  it { should allow_mass_assignment_of :n2o_amount }
  it { should allow_mass_assignment_of :cpu_multiplier }
  it { should allow_mass_assignment_of :vmem_multiplier }

  it { should have_many(:subscriptions) }
end
