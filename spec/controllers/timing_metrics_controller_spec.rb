require 'spec_helper'

describe TimingMetricsController do
  let(:user) { create :user }

  describe 'POST sftp_connection' do
    def do_request(params={})
      post :sftp_connection, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before         { sign_in user }
      let!(:region)  { create :region, name: 'us-west-2', enabled: true }
      let!(:boxhost) { create :boxhost, name: 'us-west-2', region: region }
      let!(:box)     { create :box, host: 'usw1-2.n2ostagingbox.com', boxhost: boxhost }

      context 'with valid box id' do
        it 'submits an event to Datadog responds with ok' do
          expect(DatadogEmitPointJob).to receive(:submit_job).with('nitrous_io.sftp_connection.timing', 2500, tags: [Rails.env, "region:us-west-2"], host: 'usw1-2.n2ostagingbox.com')
          do_request duration: 2500, box_id: box.id
        end

        it 'responds with :ok' do
          do_request duration: 2500, region: 'us-west-2'
          expect(controller).to respond_with :ok
        end
      end

      context 'with missing box id' do
        it 'does not submit an event to Datadog' do
          expect(DatadogEmitPointJob).to_not receive(:submit_job)
          do_request duration: 2500, box_id: 'missing'
        end

        it 'responds with :ok' do
          do_request duration: 2500, box_id: 'missing'
          expect(controller).to respond_with :ok
        end
      end

      context 'without valid duration' do
        it 'does not submit an event to Datadog' do
          expect(DatadogEmitPointJob).to_not receive(:submit_job)
          do_request duration: 'junk-duration', box_id: box.id
        end

        it 'responds with :ok' do
          do_request duration: 'junk-duration', box_id: box.id
          expect(controller).to respond_with :ok
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
