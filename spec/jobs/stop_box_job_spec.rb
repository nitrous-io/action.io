require 'spec_helper'

describe StopBoxJob do
  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { StopBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls stop! on the box' do
      box.should_receive(:stop!).once
      job.perform
    end
  end
end
