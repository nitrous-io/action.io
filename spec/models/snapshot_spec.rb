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

  describe 'validations' do
    it { should validate_presence_of(:name) }

    it { should ensure_length_of(:name).is_at_least(1).is_at_most(54) }

    it { should allow_value('fragrant wind 69 20140101').for(:name) }
    it { should allow_value('fragrant-wind-69-20140101').for(:name) }
    it { should allow_value('fragrantwind69-20140101').for(:name) }
    it { should_not allow_value('fr@gr@nt-w|nd-69-20140101').for(:name) }
    it { should_not allow_value('fragrant_wind_69-20140101').for(:name) }
    it { should_not allow_value('69-fragrant-wind-20140101').for(:name) }
    it { should_not allow_value('-fragrant-wind-69-20140101').for(:name) }
    it { should_not allow_value('fragrant-wind-69-20140101-').for(:name) }
    it { should_not allow_value('fragrant-wind-69-20140101 ').for(:name) }
    it { should_not allow_value(' fragrant-wind-69-20140101').for(:name) }
    it { should_not allow_value('향기로운-바람-69').for(:name) }
  end
end
