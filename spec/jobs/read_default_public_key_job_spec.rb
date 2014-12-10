require 'spec_helper'

describe ReadDefaultPublicKeyJob do
  describe '#perform' do
    let(:user) { mock_model(User) }
    let(:another_user) { mock_model(User) }
    let(:box) { mock_model(Box, owner: user, users: [user, another_user]) }
    let(:channel) { double.as_null_object }

    before do
      expect(Box).to receive_message_chain('running.find_by_id') { box }
    end

    context 'when owner requests the default public key of the box' do
      it 'broadcast the default public key of the box to the requester' do
        expect(ReadDefaultPublicKey).to receive(:run).with(box) { "public-key" }

        expect(Shover).to receive(:publish).with(user.id, 'aio:read_default_public_key', { box: { id: box.id, public_key: 'public-key' }})

        expect(Pusher).to receive(:[]).with("private-user-#{user.id}") { channel }
        expect(channel).to receive(:trigger) do |message, data|
          expect(message).to eq 'aio:read_default_public_key'
          expect(data).to eq({box: { id: box.id, public_key: 'public-key' }}.to_json)
        end

        ReadDefaultPublicKeyJob.new(box.id, user.id).perform
      end
    end

    context 'when a collaborator requests the default public key of the box' do
      it 'broadcast the default public key of the box to the requester' do
        expect(ReadDefaultPublicKey).to receive(:run).with(box) { "public-key" }

        expect(Shover).to receive(:publish).with(another_user.id, 'aio:read_default_public_key', { box: { id: box.id, public_key: 'public-key' }})

        expect(Pusher).to receive(:[]).with("private-user-#{another_user.id}") { channel }
        expect(channel).to receive(:trigger) do |message, data|
          expect(message).to eq 'aio:read_default_public_key'
          expect(data).to eq({box: { id: box.id, public_key: 'public-key' }}.to_json)
        end

        ReadDefaultPublicKeyJob.new(box.id, another_user.id).perform
      end
    end

    context 'when box returns no key' do
      it 'logs an error' do
        expect(ReadDefaultPublicKey).to receive(:run).and_return(nil)
        expect(Shover).to receive(:publish)
        expect(Pusher).to receive(:[]).with("private-user-#{user.id}") { channel }

        expect(Rails.logger).to receive(:error).with("Unable to read default public key for box #{box.id}")

        ReadDefaultPublicKeyJob.new(box.id, user.id).perform
      end
    end

    context 'when running box is not found' do
      it 'does nothing' do
        expect(Box).to receive_message_chain('running.find_by_id') { nil }
        expect(ReadDefaultPublicKey).not_to receive(:run)

        ReadDefaultPublicKeyJob.new(box.id, user.id).perform
      end
    end
  end
end
