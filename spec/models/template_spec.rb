require 'spec_helper'

describe Template do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :image }
  it { should allow_mass_assignment_of :description }

  it { should have_many(:boxes).dependent(:nullify) }
end
