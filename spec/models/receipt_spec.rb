require 'spec_helper'

describe Receipt do
  it { should allow_mass_assignment_of :period_start }
  it { should allow_mass_assignment_of :period_end }
  it { should allow_mass_assignment_of :lines }
  it { should allow_mass_assignment_of :subtotal }
  it { should allow_mass_assignment_of :total }

  it { should belong_to(:billing_profile) }
end
