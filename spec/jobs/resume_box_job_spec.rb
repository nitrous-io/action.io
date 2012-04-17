require 'spec_helper'

describe ResumeBoxJob do
  subject { ResumeBoxJob }

  it 'is on box_control_jobs queue' do
    subject.instance_variable_get(:@queue).should == :box_control_jobs
  end

  describe '.perform' do
    let!(:box) { create :box }
    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls resume! on the box' do
      box.should_receive(:resume!).once
      subject.perform(box.id)
    end
  end
end
