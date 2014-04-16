require 'spec_helper'

describe UserEvent do
  it { should belong_to :user }

  it { should allow_mass_assignment_of :user_id }
  it { should allow_mass_assignment_of :event }
end
