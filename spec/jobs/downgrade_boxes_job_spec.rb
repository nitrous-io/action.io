require 'spec_helper'

describe DowngradeBoxesJob do
  describe '#perform' do

    context 'when there are no boxes in states requiring restart' do
      before do
        Box.stub(:find_all_requiring_restart).with(123) { [] }
      end

      it 'should not requeue a new job' do
        job = DowngradeBoxesJob.new(123)
        job.should_not_receive(:requeue)
        job.perform
      end
    end

    context 'when there are boxes in states requiring restart and require a downgrade' do
      let!(:running_box1) { create :box, owner_id: 123 }
      let!(:running_box2) { create :box, owner_id: 123 }
      let!(:restarting_box) { create :box, owner_id: 123 }

      before do
        running_box1.stub(requires_downgrade?: true, running?: true)
        running_box2.stub(requires_downgrade?: true, running?: true)
        restarting_box.stub(requires_downgrade?: true, running?: false)
      end

      context 'when all boxes are running' do
        before do
          Box.stub(:find_all_requiring_restart).with(123) { [running_box1, running_box2] }
        end

        it 'should call enqueue_restart! on the running boxes' do
          running_box1.should_receive(:enqueue_restart!)
          running_box2.should_receive(:enqueue_restart!)
          DowngradeBoxesJob.new(123).perform
        end
      end

      context 'when there are non-running boxes' do
        before do
          Box.stub(:find_all_requiring_restart).with(123) { [running_box1, restarting_box] }
        end

        it 'should not call enqueue_restart! on boxes that are not running' do
          running_box1.stub(:enqueue_restart!)
          restarting_box.should_not_receive(:enqueue_restart!)
          DowngradeBoxesJob.new(123).perform
        end

        it 'should requeue a new job' do
          running_box1.stub(:enqueue_restart!)
          job = DowngradeBoxesJob.new(123)
          job.should_receive(:requeue).with(123)
          job.perform
        end
      end
    end

  end

  describe '#requeue' do
    let!(:job) { DowngradeBoxesJob.new(123) }

    it 'should create a new job with the given user ID from the current job' do
      Delayed::Job.stub(:enqueue)
      DowngradeBoxesJob.should_receive(:new).with(123)

      job.requeue(123)
    end

    it 'should enqueue a delayed job which soft reconfigures boxes' do
      expect {
        job.requeue(123)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/DowngradeBoxesJob/)
      Delayed::Job.last.handler.should match(/user_id: 123/)
    end
  end

  describe '.submit_job' do
    it "should submit a delayed job to downgrade a user's boxes" do
      expect {
        DowngradeBoxesJob.submit_job(123)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/DowngradeBoxesJob/)
      Delayed::Job.last.handler.should match(/user_id: 123/)
    end
  end
end
