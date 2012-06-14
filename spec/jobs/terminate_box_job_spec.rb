require 'spec_helper'

describe TerminateBoxJob do
  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { TerminateBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls terminate! on the box' do
      box.should_receive(:terminate!).once
      job.perform
    end
  end
end
