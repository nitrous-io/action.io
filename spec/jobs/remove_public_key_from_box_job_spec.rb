require 'spec_helper'

describe RemovePublicKeyFromBoxJob do
  let!(:dummy_key)  { 'ssh-rsa S0m3DummYk3Y key@example.com' }
  let!(:box)        { create :box }

  describe '#perform' do
    let!(:mock_coach) { instance_double('Coach') }
    let!(:job)        { RemovePublicKeyFromBoxJob.new(box.id, dummy_key) }

    before do
      Box.stub(:find).with(box.id) { box }
      box.stub(:coach) { mock_coach }
    end

    it 'calls remove_public_key on the coach with the key' do
      expect(box).to receive(:coach).and_return(mock_coach)
      expect(mock_coach).to receive(:remove_public_key).with(dummy_key)
      job.perform
    end
  end

  describe ".submit_job" do
    it "should submit a delayed job which will remove a public key from a box" do
      expect {
        RemovePublicKeyFromBoxJob.submit_job(box.id, dummy_key)
      }. to change(Delayed::Job, :count).by (1)

      expect(Delayed::Job.last.handler).to match(/RemovePublicKeyFromBoxJob/)
      expect(Delayed::Job.last.handler).to match(/box_id: #{box.id}/)
      expect(Delayed::Job.last.handler).to match(/key: ssh-rsa S0m3DummYk3Y key@example.com/)
    end
  end
end

