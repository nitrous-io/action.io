require 'spec_helper'

describe AddPublicKeyToBoxJob do
  subject { AddPublicKeyToBoxJob }

  it 'is on box_control_jobs queue' do
    subject.instance_variable_get(:@queue).should == :box_control_jobs
  end

  describe '.perform' do
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }
    let!(:box) { create :box }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls add_public_key on the box with the key' do
      box.should_receive(:add_public_key).with(dummy_key)
      subject.perform(box.id, dummy_key)
    end
  end
end

