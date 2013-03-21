require 'spec_helper'

describe DeleteSnapshotJob do
  let!(:snapshot) { create :snapshot, state: "snapshotted" }
  let!(:box)      { snapshot.box }
  let!(:job)      { described_class.new(snapshot.id) }

  before do
    Snapshot.any_instance.stub :push_snapshot_updated_message
    Region.any_instance.stub(:coach_uri) { "https://coach.action.io" }
  end

  it 'calles snapshot_box method on the coach' do
    req = stub_request(:put, "https://aio:foobar@coach.action.io/boxes/#{box.container_name}/delete_snapshot").
      with(query: {
        box: { boxer_id: box.host },
        return_vars: JSON.generate(snapshot_id: snapshot.id),
        snapshot_url: snapshot.url
      }).
      to_return(body: '{"status":"OK"}')
    job.perform
    req.should have_been_requested
  end
end
