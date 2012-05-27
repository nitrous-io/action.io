require 'spec_helper'

describe KeyPair do
  it { should belong_to :box }

  it { should_not allow_mass_assignment_of :private_key }
  it { should_not allow_mass_assignment_of :public_key }
end
