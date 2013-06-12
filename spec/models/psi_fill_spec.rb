require 'spec_helper'

describe PsiFill do
  it { should belong_to :user }

  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :amount }
  it { should_not allow_mass_assignment_of :kind }
  it { should_not allow_mass_assignment_of :description }
end
