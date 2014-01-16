require 'spec_helper'

describe DeletedUser do
  it { should allow_mass_assignment_of :user_id }
  it { should allow_mass_assignment_of :email }
  it { should allow_mass_assignment_of :username }
  it { should allow_mass_assignment_of :created_at }
  it { should allow_mass_assignment_of :deleted_at }
end
