require 'spec_helper'

describe DeleteSnapshotJob do
  let(:snapshot) { create :snapshot }
  let(:coach) { instance_double('Coach') }

  before do
    Snapshot.stub(:find).with(snapshot.id) { snapshot }
    snapshot.stub(:coach) { coach }
  end

  describe '#perform' do
    it 'asks Coach to delete_snapshot' do
      expect(coach).to receive(:delete_snapshot).with(snapshot)
      DeleteSnapshotJob.new(snapshot.id).perform
    end
  end

  describe '.submit_job' do
    it "should submit a delayed job to snapshot the box" do
      expect {
        described_class.submit_job(123)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(%r{#{described_class}})
      expect(Delayed::Job.last.handler).to match(/snapshot_id: 123/)
    end
  end
end
