require 'spec_helper'

describe StopBoxJob do
  subject { StopBoxJob }

  it 'is on box_control_jobs queue' do
    subject.instance_variable_get(:@queue).should == :box_control_jobs
  end

  describe '.perform' do
    let!(:box) { create :box }
    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls stop! on the box' do
      box.should_receive(:stop!).once
      subject.perform(box.id)
    end
  end
end
