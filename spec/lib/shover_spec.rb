require 'spec_helper'

describe Shover do
  let(:user) { create :user }

  before do
    Settings.stub(:shover_server_uri).and_return 'https://shover.nitrous.io'
  end

  describe '.publish' do
    let!(:publish_url) { Settings.shover_server_uri + '/publish' }

    before do
      stub_request :post, publish_url
    end

    context 'when given user id' do
      it 'makes a POST request to SHOVER_SERVER_URI/publish with a signed payload' do
        Shover.publish 123, 'foo', { bar: 123 }
        expect(a_request(:post, publish_url).with(
          body: hash_including(p: DefaultMessageVerifier.verifier.generate([123, 'foo', { bar: 123 }]))
        )).to have_been_made
      end
    end

    context 'when given user object instead' do
      it "makes a POST request to SHOVER_SERVER_URI/publish with a signed payload including the user's id" do
        Shover.publish user, 'foo', { bar: 123 }
        expect(a_request(:post, publish_url).with(
          body: hash_including(p: DefaultMessageVerifier.verifier.generate([user.id, 'foo', { bar: 123 }]))
        )).to have_been_made
      end
    end
  end

  describe '.broadcast' do
    let!(:broadcast_url) { Settings.shover_server_uri + '/broadcast' }

    before do
      stub_request :post, broadcast_url
    end

    it 'makes a POST request to SHOVER_SERVER_URI/broadcast with a signed payload' do
      Shover.broadcast 'foo', { bar: 123 }
      expect(a_request(:post, broadcast_url).with(
        body: hash_including(p: DefaultMessageVerifier.verifier.generate(['foo', { bar: 123 }]))
      )).to have_been_made
    end
  end
end
