require 'spec_helper'

describe ProvisionBoxJob do
  subject { ProvisionBoxJob }

  it 'is on box_provisioning_jobs queue' do
    subject.instance_variable_get(:@queue).should == :box_provisioning_jobs
  end

  describe '.perform' do
    let!(:box) { create :box }
    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls provision! and then start! on the box' do
      box.should_receive(:provision!).once.ordered
      box.should_receive(:enqueue_start!).once.ordered
      subject.perform(box.id)
    end
  end
end
