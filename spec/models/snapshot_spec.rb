# coding: utf-8
require 'spec_helper'

describe Snapshot do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should_not allow_mass_assignment_of :public }
  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :owner_id }

  it { should belong_to(:box) }
  it { should belong_to(:owner).class_name('User') }

  describe 'validations' do
    let!(:snapshot) { create :snapshot }

    describe '#name' do
      it { should validate_presence_of(:name) }
      it { should validate_uniqueness_of(:name).scoped_to(:owner_id) }
      it { should ensure_length_of(:name).is_at_least(4).is_at_most(40) }

      it { should allow_value('fragrant-wind-69').for(:name) }
      it { should allow_value('fragrantwind69').for(:name) }
      it { should_not allow_value('fr@gr@nt-w|nd-69').for(:name) }
      it { should_not allow_value('fragrant_wind_69').for(:name) }
      it { should_not allow_value('69-fragrant-wind').for(:name) }
      it { should_not allow_value('-fragrant-wind-69').for(:name) }
      it { should_not allow_value('fragrant-wind-69-').for(:name) }
      it { should_not allow_value('fragrant wind 69').for(:name) }
      it { should_not allow_value('향기로운-바람-69').for(:name) }
    end

    it 'validates presence of box only when snapshot is a new record' do
      snapshot.box = nil
      snapshot.should be_valid
      new_snapshot = build :snapshot, box: nil
      new_snapshot.should_not be_valid
    end

    context 'when snapshot creation is disabled' do
      let!(:allow_snapshot_creation_setting) { ENV['DISABLE_SNAPSHOT_CREATION'] }
      before { ENV['DISABLE_SNAPSHOT_CREATION'] = 'true' }
      after { ENV['DISABLE_SNAPSHOT_CREATION'] = allow_snapshot_creation_setting }

      it 'is valid when owner is admin' do
        snapshot.should_not be_valid
        admin = create :admin
        box_admin = create :box, owner: admin
        snapshot.box = box_admin
        snapshot.should be_valid
      end
    end
  end

  describe '#create' do
    it 'uses the box owner as its owner' do
      snapshot = create :snapshot
      snapshot.owner.should eq(snapshot.box.owner)
    end
  end

  describe '#finish' do
    it 'update url and state of the snapshot' do
      snapshot = create :snapshot
      snapshot.update_attribute :state, :snapshotting
      snapshot.should_receive(:push_snapshot_updated_message)
      snapshot.finish "snapshotURL"
      snapshot.reload
      snapshot.url.should eq("snapshotURL")
      snapshot.state.should eq("snapshotted")
    end
  end

  describe '#start' do
    let(:snapshot) { create :snapshot }

    it 'enqueues a box snapshotting job and change state of the snapshot' do
      SnapshotBoxJob.should_receive(:new) do |*args|
        args.should == [snapshot.id]
      end.and_return(:snapshot_box_job)

      Delayed::Job.should_receive(:enqueue).with(:snapshot_box_job)
      snapshot.should_receive :push_snapshot_updated_message

      expect {
        snapshot.start
      }.to change(snapshot, :state).from('new').to('snapshotting')
    end
  end

  describe '#push_snapshot_updated_message' do
    it 'pushes aio:snapshot_updated notification' do
      snapshot = create :snapshot
      channel = double('channel')
      Pusher.should_receive(:[]).with("private-user-#{snapshot.owner_id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:snapshot_updated', snapshot.serialize_as_hash)
      snapshot.push_snapshot_updated_message
    end
  end

  describe '#delete_snapshot' do
    let(:snapshot) { create :snapshot, state: 'snapshotted' }

    before do
      snapshot.stub :push_snapshot_updated_message
      Coach.any_instance.stub :delete_snapshot
    end

    it 'changes state of snapshot to deleted' do
      snapshot.delete_snapshot
      snapshot.reload
      snapshot.state.should eq("deleted")
    end

    it 'schedules coach to delete the snapshot' do
      expect {
        snapshot.delete_snapshot
      }.to change { Delayed::Job.count }.by 1
      job = Delayed::Job.last.payload_object
      job.should be_kind_of(DeleteSnapshotJob)
      job.snapshot_id.should eq(snapshot.id)
    end
  end
end
