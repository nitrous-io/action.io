require 'spec_helper'

describe StartBoxJob do
  describe '#perform' do
    let!(:box)        { create :box }
    let!(:mock_coach) { double('coach') }
    let!(:job)        { StartBoxJob.new(box.id) }

    before do
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach)             { mock_coach }
    end

    it 'calls start_box method on the coach' do
      box.should_receive(:coach).once.ordered.and_return(mock_coach)
      mock_coach.should_receive(:start_box).once.ordered
      job.perform
    end
  end
end
