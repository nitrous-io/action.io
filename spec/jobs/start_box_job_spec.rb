require 'spec_helper'

describe StartBoxJob do
  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { StartBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls start! on the box' do
      box.should_receive(:start!).once
      job.perform
    end
  end
end
