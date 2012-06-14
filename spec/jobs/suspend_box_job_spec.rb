require 'spec_helper'

describe SuspendBoxJob do
  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { SuspendBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls suspend! on the box' do
      box.should_receive(:suspend!).once
      job.perform
    end
  end
end
