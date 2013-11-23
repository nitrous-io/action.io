require 'spec_helper'

describe ReconfigureBoxesToNewPlanJob do
  let!(:box) { create :box, memory: 512, cpu_multiplier: 1, version: 'drogo' }
  let!(:cersei_box) { create :box, memory: 1024, cpu_multiplier: 1, version: 'cersei' }

  describe '#perform' do

    context 'with multipliers' do
      before do
        Box.stub(:find).with(box.id) { box }
        box.stub(:configuration_changed?) { true }
        box.stub(:save) { true }
        box.stub(:soft_reconfigure)
      end

      it "sets box's virtual memory according to the given virtual memory multiplier" do
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id], vmem_multiplier: 2).perform
        box.virtual_memory.should == 512 * 2
      end

      it "sets box's CPU multipler to the given cpu multiplier" do
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id], cpu_multiplier: 3).perform
        box.cpu_multiplier.should == 3
      end
    end

    context 'when box version is cersei' do
      before do
        Box.stub(:find).with(cersei_box.id) { cersei_box }
        cersei_box.stub(:configuration_changed?) { true }
        cersei_box.stub(:save) { true }
      end

      it 'should not perform a soft reconfiguration' do
        cersei_box.should_not_receive(:soft_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [cersei_box.id]).perform
      end
    end

    context 'when box configuration has changed' do
      before do
        Box.stub(:find).with(box.id) { box }
        box.stub(:configuration_changed?) { true }
        box.stub(:save) { true }
      end

      it 'should perform a soft reconfiguration' do
        box.should_receive(:soft_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id]).perform
      end
    end

    context 'when box configuration did not change' do
      before do
        Box.stub(:find).with(box.id) { box }
        box.stub(:configuration_changed?) { false }
      end

      it 'should not perform a soft reconfiguration' do
        box.should_not_receive(:soft_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id]).perform
      end
    end

    context 'when box is in reconfiguring state' do
      before do
        Box.stub(:find).with(box.id) { box }
        box.stub(:configuration_changed?) { true }
        box.stub(:reconfiguring?) { true }
        box.stub(:soft_reconfigure)
      end

      it 'should not perform a soft reconfiguration' do
        box.should_not_receive(:soft_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id]).perform
      end

      it 'should requeue a job for the box 1 minute later' do
        job = ReconfigureBoxesToNewPlanJob.new(box_ids: [box.id])
        job.should_receive(:requeue).with(box.id)

        job.perform
      end
    end
  end

  describe '#requeue' do
    let!(:job) { ReconfigureBoxesToNewPlanJob.new cpu_multiplier: 2, vmem_multiplier: 4 }

    it 'should create a new job with the given box ID and the multipliers from the current job' do
      Delayed::Job.stub(:enqueue)
      ReconfigureBoxesToNewPlanJob.should_receive(:new).with(box_ids: [123], cpu_multiplier: 2, vmem_multiplier: 4)

      job.requeue(123)
    end

    it 'should enqueue a delayed job which soft reconfigures boxes' do
      expect {
        job.requeue(123)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/ReconfigureBoxesToNewPlanJob/)
      Delayed::Job.last.handler.should match(/box_ids:.*?- 123.*?/m)
      Delayed::Job.last.handler.should match(/cpu_multiplier: 2/)
      Delayed::Job.last.handler.should match(/vmem_multiplier: 4/)
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job which soft reconfigures boxes' do
      expect {
        ReconfigureBoxesToNewPlanJob.submit_job(box_ids: [box.id, cersei_box.id], cpu_multiplier: 1, vmem_multiplier: 1)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/ReconfigureBoxesToNewPlanJob/)
      Delayed::Job.last.handler.should match(/box_ids:.*?- #{box.id}.*?- #{cersei_box.id}/m)
      Delayed::Job.last.handler.should match(/cpu_multiplier: 1/)
      Delayed::Job.last.handler.should match(/vmem_multiplier: 1/)
    end
  end
end
