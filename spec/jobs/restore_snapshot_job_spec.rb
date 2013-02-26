require 'snapshot'

describe RestoreSnapshotJob do
  let!(:snapshot) { create :snapshot }
  let!(:box)      { snapshot.box }
  let!(:job)      { described_class.new(box.id, snapshot.id) }

  it 'calles snapshot_box method on the coach' do
    req = stub_request(:put, "https://aio:foobar@coach-1/boxes/#{box.container_name}/restore_snapshot").
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
