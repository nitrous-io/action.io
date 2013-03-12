require 'spec_helper'

describe SnapshotBoxJob do
  let!(:snapshot)   { create :snapshot }
  let!(:box)        { mock_model(Box) }
  let!(:mock_coach) { double('coach') }
  let!(:job)        { described_class.new(snapshot.id) }

  before do
    Snapshot.stub(:find).with(snapshot.id) { snapshot }
    snapshot.stub(:box) { box }
    box.stub(:coach) { mock_coach }
  end

  it 'calls snapshot_box method on the coach' do
    box.should_receive(:coach) { mock_coach }
    mock_coach.should_receive(:snapshot_box).with(snapshot)
    job.perform
  end
end
