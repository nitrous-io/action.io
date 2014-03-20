require 'spec_helper'

describe TimingMetricsController do
  let(:user) { create :user }

  describe 'POST sftp_connection' do
    def do_request(params={})
      post :sftp_connection, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }
      let!(:region) { create :region, name: 'us-west-2' }

      context 'with valid region name' do
        it 'submits an event to Datadog responds with ok' do
          expect(DatadogEmitPointJob).to receive(:submit_job).with('nitrous_io.sftp_connection.timing', 2500, tags: [Rails.env, "region:us-west-2"])
          do_request duration: 2500, region: 'us-west-2'
        end

        it 'responds with :ok' do
          do_request duration: 2500, region: 'us-west-2'
          expect(controller).to respond_with :ok
        end
      end

      context 'without valid region name' do
        it 'does not submit an event to Datadog' do
          expect(DatadogEmitPointJob).to_not receive(:submit_job)
          do_request duration: 2500, region: 'antarctica'
        end

        it 'responds with :ok' do
          do_request duration: 2500, region: 'antarctica'
          expect(controller).to respond_with :ok
        end
      end

      context 'without valid duration' do
        it 'does not submit an event to Datadog' do
          expect(DatadogEmitPointJob).to_not receive(:submit_job)
          do_request duration: 'junk-duration', region: 'us-west-2'
        end

        it 'responds with :ok' do
          do_request duration: 'junk-duration', region: 'us-west-2'
          expect(controller).to respond_with :ok
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
