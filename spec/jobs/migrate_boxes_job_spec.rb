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
    allow_any_instance_of(Box).to receive(:push_box_updated_message).and_return nil
    allow_any_instance_of(Coach).to receive(:migrate).and_return nil
  end

  it 'process a set of arya and bran boxes for the specified region at a time' do
    job.num_box = 4
    job.perform
    expect(box_1.reload.state).to eq("migrating")
    expect(box_2.reload.state).to eq("running")
    expect(box_3.reload.state).to eq("migrating")
    expect(box_4.reload.state).to eq("terminated")
    expect(box_5.reload.state).to eq("running")
  end

  it 'schedules the next job to process again' do
    Timecop.freeze do
      job.perform
      new_job = Delayed::Job.last
      payload = new_job.payload_object
      expect(payload).to be_kind_of(described_class)
      expect(new_job.run_at.to_i).to eq(next_run.from_now.to_i)
    end
  end

  it 'does not schedule any job when there isnt more boxes' do
    2.times { job.perform }
    expect {
      job.perform
    }.to_not change { Delayed::Job.count }
  end
end
