require 'spec_helper'

describe AddPublicKeyToBoxJob do
  describe '#perform' do
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }
    let!(:box) { create :box }
    let!(:job) { AddPublicKeyToBoxJob.new(box.id, dummy_key) }

    before { Box.stub!(:find).with(box.id) { box } }

    it 'calls add_public_key on the box with the key' do
      box.should_receive(:add_public_key).with(dummy_key)
      job.perform
    end
  end
end

