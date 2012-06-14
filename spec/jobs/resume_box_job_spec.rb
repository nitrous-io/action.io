require 'spec_helper'

describe ResumeBoxJob do
  describe '#perform' do
    let!(:box) { create :box }
    let!(:job) { ResumeBoxJob.new(box.id) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls resume! on the box' do
      box.should_receive(:resume!).once
      job.perform
    end
  end
end
