require 'spec_helper'

describe BoxTemplate do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :runtime }
  it { should allow_mass_assignment_of :enabled }

  it { should have_many(:boxes).dependent(:nullify) }
end
