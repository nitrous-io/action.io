require 'spec_helper'

describe PlanGroup do
  it { should allow_mass_assignment_of :name }

  describe 'validations' do
    let!(:plan_group) { create :plan_group }

    it { should validate_presence_of :name    }
    it { should validate_uniqueness_of :name  }
  end

  describe 'Associations' do
    it { should have_many :users }
  end
end
