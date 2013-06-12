require 'spec_helper'

describe KeyValue do
  it { should allow_mass_assignment_of :key }
  it { should allow_mass_assignment_of :value }
end
