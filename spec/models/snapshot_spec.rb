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
      let(:snapshot_7) { create :snapshot, state: 'deleted', created_at: 7.days.ago }

      before do
        Timecop.freeze
        snapshot_1; snapshot_2; snapshot_3; snapshot_4; snapshot_5; snapshot_6; snapshot_7
      end

      after { Timecop.return }

      describe '.undeleted' do
        it 'should return all but deleted snapshots' do
          expect(Snapshot.undeleted).to match_array [snapshot_1, snapshot_2, snapshot_3, snapshot_4, snapshot_5, snapshot_6]
        end
      end

      describe '.chronological_order' do
        it 'should return snapshots in order from most recently created to the oldest' do
          expect(Snapshot.chronological_order.to_a).to eql [snapshot_2, snapshot_3, snapshot_4, snapshot_1, snapshot_5, snapshot_6, snapshot_7]
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

  describe '#create' do
    context 'when it belongs to a box' do
      let(:user) { create :user }
      let(:box) { create :box, owner: user }

      it "sets its user to its box's owner" do
        snapshot = create :snapshot, box: box
        expect(snapshot.user).to eql user
      end
    end
  end

  describe 'state machine' do
    let!(:snapshot) { create :snapshot }

    it 'should have an initial state of requested' do
      expect(snapshot.state).to eql 'requested'
    end

    describe '#initiate' do
      it 'initiates a snapshot job and changes state to initiated' do
        expect(snapshot).to receive(:initiate_snapshot_job)

        expect {
          snapshot.initiate!
        }.to change { snapshot.state }.from('requested').to('initiated')
      end
    end

    describe '#mark_completed' do
      before do
        snapshot.update_attribute :state, 'initiated'
        Timecop.freeze
        @now = Time.now
      end

      after { Timecop.return }

      it 'changes state to completed' do
        expect {
          snapshot.mark_completed!
        }.to change { snapshot.state }.from('initiated').to('completed')
      end

      it 'sets the completed_at property to now' do
        snapshot.mark_completed!
        expect(snapshot.completed_at).to eql @now
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

  describe '#coach' do
    let(:box) { create :box }
    let(:snapshot) { create :snapshot, box: box }
    let(:coach) { instance_double('Coach') }

    before { allow(box).to receive(:coach).and_return(coach) }

    it "returns its box's Coach instance" do
      expect(snapshot.coach).to eql coach
    end
  end

  describe '#push_snapshot_updated_message' do
    let(:snapshot) { create :snapshot }

    it 'pushes an aio:snapshot_updated message to its user' do
      expect(Shover).to receive(:publish).with(snapshot.user.id, 'aio:snapshot_updated', snapshot.serialize_as_hash)
      snapshot.push_snapshot_updated_message
    end
  end

  describe '#initiate_snapshot_job' do
    let(:snapshot) { create :snapshot }

    it 'enqueues a snapshot box job' do
      expect(SnapshotBoxJob).to receive(:submit_job).with(snapshot.id)
      snapshot.initiate_snapshot_job
    end
  end

  describe '#delete_snapshot_job' do
    let(:snapshot) { create :snapshot }

    it 'enqueues a delete snapshot job' do
      expect(DeleteSnapshotJob).to receive(:submit_job).with(snapshot.id)
      snapshot.delete_snapshot_job
    end
  end
end
