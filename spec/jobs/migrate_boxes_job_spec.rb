require 'spec_helper'

describe MigrateBoxesJob do
  let!(:num_box) { 2 }
  let!(:next_run) { 10.minutes }
  let!(:region_1) { create :region, enabled: true }
  let!(:region_2) { create :region, enabled: true }
  let(:job) { described_class.new region_1.id, %w(running stopped), num_box, next_run }

  let!(:box_1) { create :box, state: 'running', region: region_1, version: "bran" }
  let!(:box_2) { create :box, state: 'running', region: region_1, version: "cersei" }
  let!(:box_3) { create :box, state: 'stopped', region: region_1, version: "arya" }
  let!(:box_4) { create :box, state: 'terminated', region: region_1, version: "arya" }
  let!(:box_5) { create :box, state: 'running', region: region_2, version: "arya" }

  before do
    Box.any_instance.stub :push_box_updated_message
    Coach.any_instance.stub :migrate
  end

  it 'process a set of arya and bran boxes for the specified region at a time' do
    job.num_box = 4
    job.perform
    box_1.reload.state.should eq("migrating")
    box_2.reload.state.should eq("running")
    box_3.reload.state.should eq("migrating")
    box_4.reload.state.should eq("terminated")
    box_5.reload.state.should eq("running")
  end

  it 'schedules the next job to process again' do
    Timecop.freeze do
      job.perform
      new_job = Delayed::Job.last
      payload = new_job.payload_object
      payload.should be_kind_of(described_class)
      new_job.run_at.to_i.should eq(next_run.from_now.to_i)
    end
  end

  it 'does not schedule any job when there isnt more boxes' do
    2.times { job.perform }
    expect {
      job.perform
    }.to_not change { Delayed::Job.count }
  end
end
