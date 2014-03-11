require 'spec_helper'

describe TimingMetricsController do
  let(:user) { create :user }

  describe 'POST sftp_connection' do
    def do_request(params={})
      post :sftp_connection, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      it 'respnds with ok' do
        do_request duration: 2500
        expect(controller).to respond_with :ok
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
