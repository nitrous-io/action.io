require 'spec_helper'

describe BoxTransition do
  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :event }
  it { should_not allow_mass_assignment_of :from_state }
  it { should_not allow_mass_assignment_of :to_state }
  it { should_not allow_mass_assignment_of :triggered_by }

  it { should belong_to(:user) }
  it { should belong_to(:box) }

  describe 'validations' do
    it { should validate_presence_of(:box) }
    it { should validate_presence_of(:event) }
    it { should validate_presence_of(:from_state) }
    it { should validate_presence_of(:to_state) }
    it { should validate_presence_of(:triggered_by) }

    it { should allow_value('admin').for(:triggered_by) }
    it { should_not allow_value('some admin').for(:triggered_by) }

    describe 'triggered_by user requires user_id' do
      let(:user) { build :user }
      let(:box_transition) { BoxTransition.new }

      it 'requires user if triggered_by is "user"' do
        box_transition.triggered_by = 'user'
        expect(box_transition.error_on(:user)).to include(match(/triggered_by is user/))
        box_transition.user = user
        expect(box_transition.error_on(:user)).to be_empty
      end
    end
  end

  describe 'defaults' do
    it 'triggered_by to unknown' do
      expect(BoxTransition.new.triggered_by).to eql('unknown')
    end
  end
end
