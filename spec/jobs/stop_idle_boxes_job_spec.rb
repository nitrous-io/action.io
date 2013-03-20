require 'spec_helper'

describe StopIdleBoxesJob do
  let!(:num_box) { 2 }
  let!(:next_run) { 10.minutes }
  let(:job) { described_class.new num_box, next_run }

  let!(:box_1) { create :box, state: 'running', touched_at: 1.day.ago }
  let!(:box_2) { create :box, state: 'running', touched_at: 2.days.ago }
  let!(:box_3) { create :box, state: 'running', touched_at: 1.year.ago }

  before do
    Box.any_instance.stub :push_box_updated_message
    Coach.any_instance.stub :stop_box
  end

  it 'process a set of idle boxes at a time' do
    job.perform
    box_1.reload.state.should eq("running")
    box_2.reload.state.should eq("running")
    box_3.reload.state.should eq("stopping")
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

  it 'does not schedule any job when there isnt any idle boxes' do
    2.times { job.perform }
    expect {
      job.perform
    }.to_not change { Delayed::Job.count }
  end
end
