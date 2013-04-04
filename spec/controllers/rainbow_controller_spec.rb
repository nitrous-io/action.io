require 'spec_helper'

describe RainbowController do
  let(:user) { create :user }

  describe 'GET auth_token' do
    def do_request
      get :auth_token, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      it 'creates and returns an oauth token' do
        Timecop.freeze do
          do_request

          expect(response.body).to eq({
            auth_token: AuthToken.generate(user, 'rainbow')
          }.to_json)
        end
      end

      it_behaves_like 'an action that is not cacheable'
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
