require 'spec_helper'

describe AddPublicKeyToBoxJob do
  let!(:dummy_key)  { 'ssh-rsa S0m3DummYk3Y key@example.com' }
  let!(:box)        { create :box }

  describe '#perform' do
    let!(:mock_coach) { double('coach') }
    let!(:job)        { AddPublicKeyToBoxJob.new(box.id, dummy_key) }

    before do
      Box.stub!(:find).with(box.id) { box }
      box.stub!(:coach) { mock_coach }
    end

    it 'calls add_public_key on the box with the key' do
      box.should_receive(:coach).and_return(mock_coach)
      mock_coach.should_receive(:add_public_key).with(dummy_key)
      job.perform
    end
  end

  describe ".submit_job" do
    it "should submit a delayed job which will add a public key to a box" do
      expect {
        AddPublicKeyToBoxJob.submit_job(box.id, dummy_key)
      }. to change(Delayed::Job, :count).by (1)

      Delayed::Job.last.handler.should match(/AddPublicKeyToBoxJob/)
      Delayed::Job.last.handler.should match(/box_id: #{box.id}/)
      Delayed::Job.last.handler.should match(/key: ssh-rsa S0m3DummYk3Y key@example.com/)
    end
  end
end

