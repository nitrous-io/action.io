require 'spec_helper'

describe ReconfigureBoxesToNewPlanJob do
  let!(:box1) { create :box, memory: 512, cpu_multiplier: 1 }
  let!(:box2) { create :box, memory: 1024, cpu_multiplier: 1 }

  describe '#perform' do

    context 'with multipliers' do
      before do
        Box.stub(:find).with(box1.id) { box1 }
        box1.stub(:configuration_changed?) { true }
        box1.stub(:save) { true }
        box1.stub(:enqueue_reconfigure)
      end

      it "sets box's virtual memory according to the given virtual memory multiplier" do
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box1.id], vmem_multiplier: 2).perform
        box1.virtual_memory.should == 512 * 2
      end

      it "sets box's CPU multipler to the given cpu multiplier" do
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box1.id], cpu_multiplier: 3).perform
        box1.cpu_multiplier.should == 3
      end
    end

    context 'when box configuration has changed' do
      before do
        Box.stub(:find).with(box1.id) { box1 }
        box1.stub(:configuration_changed?) { true }
        box1.stub(:save) { true }
      end

      it 'should enqueue reconfiguration' do
        box1.should_receive(:enqueue_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box1.id]).perform
      end
    end

    context 'when box configuration did not change' do
      before do
        Box.stub(:find).with(box1.id) { box1 }
        box1.stub(:configuration_changed?) { false }
      end

      it 'should not enqueue reconfiguration' do
        box1.should_not_receive(:enqueue_reconfigure)
        ReconfigureBoxesToNewPlanJob.new(box_ids: [box1.id]).perform
      end
    end
  end

  describe '.submit_job' do
    it "should submit a delayed job which reconfigures boxes" do
      expect {
        ReconfigureBoxesToNewPlanJob.submit_job(box_ids: [box1.id, box2.id], cpu_multiplier: 1, vmem_multiplier: 1)
      }. to change(Delayed::Job, :count).by (1)

      Delayed::Job.last.handler.should match(/ReconfigureBoxesToNewPlanJob/)
      Delayed::Job.last.handler.should match(/box_ids:.*?- #{box1.id}.*?- #{box2.id}/m)
      Delayed::Job.last.handler.should match(/cpu_multiplier: 1/)
      Delayed::Job.last.handler.should match(/vmem_multiplier: 1/)
    end
  end
end
