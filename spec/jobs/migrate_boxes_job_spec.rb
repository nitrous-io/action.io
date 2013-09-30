require 'spec_helper'

describe MigrateBoxesJob do
  let!(:num_box) { 2 }
  let!(:next_run) { 10.minutes }
  let(:job) { described_class.new num_box, next_run }

  let!(:box_1) { create :box, state: 'running' }
  let!(:box_2) { create :box, state: 'running' }
  let!(:box_3) { create :box, state: 'running' }

  before do
    Box.any_instance.stub :push_box_updated_message
    Coach.any_instance.stub :migrate
  end

  it 'process a set of boxes at a time' do
    job.perform
    box_1.reload.state.should eq("migrating")
    box_2.reload.state.should eq("migrating")
    box_3.reload.state.should eq("running")
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
