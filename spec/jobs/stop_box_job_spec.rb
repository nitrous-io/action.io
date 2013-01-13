require 'spec_helper'

describe StopBoxJob do
  describe '#perform' do
    let(:box)        { create :box }
    let(:mock_coach) { double('coach') }
    let(:job)        { StopBoxJob.new(box.id) }

    before do
      Box.any_instance.stub :push_box_added_message
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach)             { mock_coach }
    end

    it 'calls stop_box method on the coach' do
      box.should_receive(:coach).once.ordered.and_return(mock_coach)
      mock_coach.should_receive(:stop_box).once.ordered
      job.perform
    end
  end
end
