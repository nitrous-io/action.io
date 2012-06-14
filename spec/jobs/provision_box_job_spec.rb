require 'spec_helper'

describe ProvisionBoxJob do

  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { ProvisionBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls provision! and then start! on the box' do
      box.should_receive(:provision!).once.ordered
      box.should_receive(:enqueue_start!).once.ordered
      job.perform
    end
  end
end
