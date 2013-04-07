require 'spec_helper'

describe BoxUser do
  it { should belong_to :box }
  it { should belong_to :user }

  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :user_id }
end
