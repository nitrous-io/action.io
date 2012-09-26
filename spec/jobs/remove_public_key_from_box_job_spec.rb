require 'spec_helper'

describe RemovePublicKeyFromBoxJob do
  describe '#perform' do
    let!(:dummy_key)  { 'ssh-rsa S0m3DummYk3Y key@example.com' }
    let!(:box)        { create :box }
    let!(:mock_coach) { double('coach') }
    let!(:job)        { RemovePublicKeyFromBoxJob.new(box.id, dummy_key) }

    before do
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach) { mock_coach }
    end

    it 'calls remove_public_key on the coach with the key' do
      box.should_receive(:coach).and_return(mock_coach)
      mock_coach.should_receive(:remove_public_key).with(dummy_key)
      job.perform
    end
  end
end

