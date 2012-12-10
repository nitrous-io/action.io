require 'spec_helper'

describe AddPublicKeyToBoxJob do
  describe '#perform' do
    let(:dummy_key)  { 'ssh-rsa S0m3DummYk3Y key@example.com' }
    let(:box)        { create :box }
    let(:mock_coach) { double('coach') }
    let(:job)        { AddPublicKeyToBoxJob.new(box.id, dummy_key) }

    before do
      Box.any_instance.stub :push_box_added_message
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach) { mock_coach }
    end

    it 'calls add_public_key on the box with the key' do
      box.should_receive(:coach).and_return(mock_coach)
      mock_coach.should_receive(:add_public_key).with(dummy_key)
      job.perform
    end
  end
end
