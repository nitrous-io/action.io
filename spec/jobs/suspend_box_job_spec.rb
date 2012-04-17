require 'spec_helper'

describe SuspendBoxJob do
  subject { SuspendBoxJob }

  it 'is on box_control_jobs queue' do
    subject.instance_variable_get(:@queue).should == :box_control_jobs
  end

  describe '.perform' do
    let!(:box) { create :box }
    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls suspend! on the box' do
      box.should_receive(:suspend!).once
      subject.perform(box.id)
    end
  end
end
