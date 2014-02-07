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
    it { should validate_presence_of(:box) }

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

  describe 'scopes' do
    context 'with snapshots in various states' do
      let(:snapshot_1) { create :snapshot, state: 'requested', created_at: 4.days.ago }
      let(:snapshot_2) { create :snapshot, state: 'initiated', created_at: 1.day.ago }
      let(:snapshot_3) { create :snapshot, state: 'completed', created_at: 2.days.ago }
      let(:snapshot_4) { create :snapshot, state: 'failed', created_at: 3.days.ago }
      let(:snapshot_5) { create :snapshot, state: 'requested', created_at: 5.days.ago }
      let(:snapshot_6) { create :snapshot, state: 'initiated', created_at: 6.days.ago }

      before do
        Timecop.freeze
        snapshot_1; snapshot_2; snapshot_3; snapshot_4; snapshot_5; snapshot_6
      end

      after { Timecop.return }

      describe '.chronological_order' do
        it 'should return snapshots in order from most recently created to the oldest' do
          expect(Snapshot.chronological_order.to_a).to eql [snapshot_2, snapshot_3, snapshot_4, snapshot_1, snapshot_5, snapshot_6]
        end
      end

      describe '.recently_requested' do
        it 'should return requested snapshots in order from most recently created to the oldest' do
          expect(Snapshot.recently_requested.to_a).to eql [snapshot_1, snapshot_5]
        end
      end

      describe '.recently_initiated' do
        it 'should return initiated snapshots in order from most recently created to the oldest' do
          expect(Snapshot.recently_initiated.to_a).to eql [snapshot_2, snapshot_6]
        end
      end
    end
  end

  describe 'state machine' do
    let!(:snapshot) { create :snapshot }

    it 'should have an initial state of requested' do
      expect(snapshot.state).to eql 'requested'
    end

    describe '#initiate' do
      it 'changes state to initiated' do
        expect {
          snapshot.initiate!
        }.to change { snapshot.state }.from('requested').to('initiated')
      end
    end

    describe '#mark_completed' do
      before { snapshot.update_attribute :state, 'initiated' }

      it 'changes state to completed' do
        expect {
          snapshot.mark_completed!
        }.to change { snapshot.state }.from('initiated').to('completed')
      end
    end

    describe '#mark_failed' do
      before { snapshot.update_attribute :state, 'initiated' }

      it 'changes state to failed' do
        expect {
          snapshot.mark_failed!
        }.to change { snapshot.state }.from('initiated').to('failed')
      end
    end
  end

  describe '.most_recently_requested' do
    context 'when there are requested snapshots' do
      let(:snapshot_1) { create :snapshot, state: 'requested', created_at: 1.day.ago }
      let(:snapshot_2) { create :snapshot, state: 'initiated', created_at: 1.day.ago }
      let(:snapshot_3) { create :snapshot, state: 'completed', created_at: 1.days.ago }
      let(:snapshot_4) { create :snapshot, state: 'requested', created_at: 2.days.ago }

      before do
        Timecop.freeze
        snapshot_1; snapshot_2; snapshot_3; snapshot_4
      end

      after { Timecop.return }

      it 'returns the most recently created snapshot in the requested state' do
        expect(Snapshot.most_recently_requested).to eql snapshot_1
      end
    end

    context 'when there are no requested snapshots' do
      let!(:snapshot_1) { create :snapshot, state: 'failed' }
      let!(:snapshot_2) { create :snapshot, state: 'initiated' }

      it 'returns nil' do
        expect(Snapshot.most_recently_requested).to be_nil
      end
    end
  end

  describe '.most_recently_initiated' do
    context 'when there are initiated snapshots' do
      let(:snapshot_1) { create :snapshot, state: 'requested', created_at: 1.day.ago }
      let(:snapshot_2) { create :snapshot, state: 'initiated', created_at: 1.day.ago }
      let(:snapshot_3) { create :snapshot, state: 'completed', created_at: 1.days.ago }
      let(:snapshot_4) { create :snapshot, state: 'initiated', created_at: 2.days.ago }

      before do
        Timecop.freeze
        snapshot_1; snapshot_2; snapshot_3; snapshot_4
      end

      after { Timecop.return }

      it 'returns the most recently created snapshot in the initiated state' do
        expect(Snapshot.most_recently_initiated).to eql snapshot_2
      end
    end

    context 'when there are no initiated snapshots' do
      let!(:snapshot_1) { create :snapshot, state: 'failed' }
      let!(:snapshot_2) { create :snapshot, state: 'requested' }

      it 'returns nil' do
        expect(Snapshot.most_recently_initiated).to be_nil
      end
    end
  end
end
