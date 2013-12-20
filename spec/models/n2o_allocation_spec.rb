require 'spec_helper'

describe N2oAllocation do
  it { should belong_to :user }
  it { should belong_to :resource }

  it { should_not allow_mass_assignment_of :user_id }
  it { should_not allow_mass_assignment_of :resource_id }
  it { should_not allow_mass_assignment_of :resource_type }
  it { should_not allow_mass_assignment_of :amount }
  it { should_not allow_mass_assignment_of :kind }
  it { should_not allow_mass_assignment_of :deallocated_at }

  describe 'scopes' do
    let!(:object)  { create :n2o_allocation, amount: 500 }
    let!(:object2) { create :n2o_allocation, amount: 150, deallocated_at: Time.now }
    let!(:object3) { create :n2o_allocation, amount: 200 }
    let!(:object4) { create :n2o_allocation, amount:  40, deallocated_at: Time.now }

    describe '.allocated' do
      it 'returns objects that are not deallocated' do
        expect(N2oAllocation.allocated).to match_array([object, object3])
      end
    end

    describe '.deallocated' do
      it 'returns objects that are deallocated' do
        expect(N2oAllocation.deallocated).to match_array([object2, object4])
      end
    end
  end

  describe '#deallocated?' do
    subject { create :n2o_allocation }

    context 'when deallocate_at is not set' do
      it { should_not be_deallocated }
    end

    context 'when deallocated_at is set' do
      before { subject.update_attribute :deallocated_at, Time.now }
      it { should be_deallocated }
    end
  end

  describe '#deallocate!' do
    subject { create :n2o_allocation, amount: 500 }

    context 'when the object is not yet deallocated' do
      it 'sets deallocated_at and saves' do
        expect(subject.deallocated_at).to be_nil

        time = nil
        Timecop.freeze do
          time = Time.now
          subject.deallocate!
        end

        expect(subject.deallocated_at).to eq time
      end
    end

    context 'when the object is already deallocated' do
      it 'does not update deallocated_at' do
        prev_dealloc_time = 1.day.ago
        subject.update_attribute :deallocated_at, prev_dealloc_time
        subject.deallocate!
        expect(subject.deallocated_at).to eq prev_dealloc_time
      end
    end
  end
end
