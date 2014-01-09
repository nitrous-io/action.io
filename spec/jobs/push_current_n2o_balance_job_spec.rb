require 'spec_helper'

describe PushCurrentN2oBalanceJob do
  describe '#perform' do
    let!(:user)   { create :user }
    let(:channel) { double.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
      channel.stub(:trigger)
    end

    context 'when user exist' do
      it "sends the user's N2O info as a serialized JSON object to the web app via Shover" do
        expect(Shover).to receive(:publish).with(user.id, 'aio:n2o_updated', { n2o: { max: user.max_n2o, used: user.used_n2o }})
        expect(channel).to receive(:trigger) do |message, data|
          expect(message).to eq 'aio:n2o_updated'
          expect(data).to eq({n2o: { max: user.max_n2o, used: user.used_n2o }})
        end

        PushCurrentN2oBalanceJob.new(user.id).perform
      end
    end

    context 'when user doesnt exist' do
      it "doesnt send the user's N2O info as a serialized JSON object to the web app via Shover" do
        expect(Shover).to_not receive(:publish)
        expect(channel).to_not receive(:trigger)

        PushCurrentN2oBalanceJob.new(999999).perform
      end
    end
  end

  describe '.submit_job' do
    let!(:user) { create :user }

    it 'should submit a delayed job' do
      expect {
        PushCurrentN2oBalanceJob.submit_job(user)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/PushCurrentN2oBalanceJob.*?user_id: #{user.id}/m)
    end
  end
end


