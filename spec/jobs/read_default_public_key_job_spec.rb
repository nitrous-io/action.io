require 'spec_helper'

describe ReadDefaultPublicKeyJob do
  describe '#perform' do
    let(:user) { mock_model(User) }
    let(:box) { mock_model(Box, owner: user) }
    let(:job) { described_class.new box.id }
    let(:channel) { stub.as_null_object }

    before do
      Box.stub(:find).with(box.id) { box }
    end

    it 'broadcast to the box owner the default public key of the box' do
      Pusher.should_receive(:[]).with("private-user-#{box.owner.id}") { channel }
      ReadDefaultPublicKey.should_receive(:run).with(box) { "public-key" }
      channel.should_receive(:trigger) do |message, data|
        message.should eq 'aio:read_default_public_key'
        data.should eq({box: { id: box.id, public_key: 'public-key' }}.to_json)
      end
      job.perform
    end
  end
end
