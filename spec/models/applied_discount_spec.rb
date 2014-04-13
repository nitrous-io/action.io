require 'spec_helper'

describe AppliedDiscount do
  it { should allow_mass_assignment_of :percent_off }
  it { should allow_mass_assignment_of :amount_off }
  it { should allow_mass_assignment_of :stripe_customer_id }
  it { should allow_mass_assignment_of :started_at }
  it { should allow_mass_assignment_of :ended_at }
end
