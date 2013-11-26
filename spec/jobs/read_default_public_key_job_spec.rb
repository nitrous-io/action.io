require 'spec_helper'

describe ReadDefaultPublicKeyJob do
  describe '#perform' do
    let(:user) { mock_model(User) }
    let(:another_user) { mock_model(User) }
    let(:box) { mock_model(Box, owner: user, users: [user, another_user]) }
    let(:channel) { double.as_null_object }

    before do
      Box.stub(:find).with(box.id) { box }
    end

    context 'when owner requests the default public key of the box' do
      it 'broadcast the default public key of the box to the requester' do
        ReadDefaultPublicKey.should_receive(:run).with(box) { "public-key" }

        expect(Shover).to receive(:publish).with(user.id, 'aio:read_default_public_key', { box: { id: box.id, public_key: 'public-key' }})

        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
        channel.should_receive(:trigger) do |message, data|
          message.should eq 'aio:read_default_public_key'
          data.should eq({box: { id: box.id, public_key: 'public-key' }}.to_json)
        end

        ReadDefaultPublicKeyJob.new(box.id, user.id).perform
      end
    end

    context 'when a collaborator requests the default public key of the box' do
      it 'broadcast the default public key of the box to the requester' do
        ReadDefaultPublicKey.should_receive(:run).with(box) { "public-key" }

        expect(Shover).to receive(:publish).with(another_user.id, 'aio:read_default_public_key', { box: { id: box.id, public_key: 'public-key' }})

        Pusher.should_receive(:[]).with("private-user-#{another_user.id}") { channel }
        channel.should_receive(:trigger) do |message, data|
          message.should eq 'aio:read_default_public_key'
          data.should eq({box: { id: box.id, public_key: 'public-key' }}.to_json)
        end

        ReadDefaultPublicKeyJob.new(box.id, another_user.id).perform
      end
    end
  end
end
