require 'spec_helper'

describe Snapshot do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :url }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :completed_at }

  it { should belong_to(:user) }
  it { should belong_to(:box) }
  it { should have_many(:boxes) }
end
