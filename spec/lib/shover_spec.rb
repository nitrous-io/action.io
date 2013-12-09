require 'spec_helper'

describe Shover do
  let(:user) { create :user }

  before do
    Settings.stub(:shover_server_uri).and_return 'https://shover.nitrous.io'
  end

  describe '.publish' do
    context 'when data is not hash' do
      it 'raises exception' do
        expect {
          Shover.publish 123, 'foo', 'haha'
        }.to raise_error Shover::ArgumentError, /hash/
      end
    end

    context 'when data is hash' do
      context 'when post_publish succeeds with no error' do
        before { Shover.stub :post_publish }

        it 'does not create a delayed job' do
          Timecop.freeze do
            expect {
              Shover.publish 123, 'foo', { bar: 123 }
            }.not_to change { Delayed::Job.count }
            expect(Shover).to have_received(:post_publish).with(123, 'foo', { bar: 123 }, Time.now.to_i).once
          end
        end
      end

      context 'when post_publish raises exception (e.g. due to timeout)' do
        before do
          ShoverJob.stub :submit_job
          Shover.stub(:post_publish) { raise Net::OpenTimeout }
        end

        it 'creates a delayed job to retry later' do
          Timecop.freeze do
            Shover.publish 123, 'foo', { bar: 123 }
            expect(Shover).to have_received(:post_publish).with(123, 'foo', { bar: 123 }, Time.now.to_i).once
            expect(ShoverJob).to have_received(:submit_job).with(123, 'foo', { bar: 123 }, Time.now.to_i).once
          end
        end
      end
    end
  end

  describe '.broadcast' do
    context 'when data is not hash' do
      it 'raises exception' do
        expect {
          Shover.broadcast 'foo', 'haha'
        }.to raise_error Shover::ArgumentError, /hash/
      end
    end

    context 'when data is hash' do
      context 'when post_broadcast succeeds with no error' do
        before { Shover.stub :post_broadcast }

        it 'does not create a delayed job' do
          Timecop.freeze do
            expect {
              Shover.broadcast 'foo', { bar: 123 }
            }.not_to change { Delayed::Job.count }
            expect(Shover).to have_received(:post_broadcast).with('foo', { bar: 123 }, Time.now.to_i).once
          end
        end
      end

      context 'when post_broadcast raises exception (e.g. due to timeout)' do
        before do
          ShoverJob.stub :submit_job
          Shover.stub(:post_broadcast) { raise Net::OpenTimeout }
        end

        it 'creates a delayed job to retry later' do
          Timecop.freeze do
            Shover.broadcast 'foo', { bar: 123 }
            expect(Shover).to have_received(:post_broadcast).with('foo', { bar: 123 }, Time.now.to_i).once
            expect(ShoverJob).to have_received(:submit_job).with(nil, 'foo', { bar: 123 }, Time.now.to_i).once
          end
        end
      end
    end
  end

  describe '.post_publish' do
    let!(:publish_url) { Settings.shover_server_uri + '/publish' }
    before { stub_request :post, publish_url }

    context 'when given user id' do
      it 'makes a POST request to SHOVER_SERVER_URI/publish with a signed payload and the timestamp' do
        Shover.post_publish 123, 'foo', { bar: 123 }, 1386602313
        expect(a_request(:post, publish_url).with(
          body: hash_including(p: DefaultMessageVerifier.verifier.generate([123, 'foo', { bar: 123, _t: 1386602313 }]))
        )).to have_been_made
      end
    end

    context 'when given user object instead' do
      it "makes a POST request to SHOVER_SERVER_URI/publish with a signed payload including the user's id" do
        Shover.post_publish user, 'foo', { bar: 123 }, 1386602112
        expect(a_request(:post, publish_url).with(
          body: hash_including(p: DefaultMessageVerifier.verifier.generate([user.id, 'foo', { bar: 123, _t: 1386602112 }]))
        )).to have_been_made
      end
    end
  end

  describe '.post_broadcast' do
    let!(:broadcast_url) { Settings.shover_server_uri + '/broadcast' }
    before { stub_request :post, broadcast_url }

    it 'makes a POST request to SHOVER_SERVER_URI/broadcast with a signed payload' do
      Shover.post_broadcast 'foo', { bar: 123 }, 1386602200
      expect(a_request(:post, broadcast_url).with(
        body: hash_including(p: DefaultMessageVerifier.verifier.generate(['foo', { bar: 123, _t: 1386602200 }]))
      )).to have_been_made
    end
  end
end
