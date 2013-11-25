require 'spec_helper'

describe AuthTokenController do
  let(:user) { create :user }

  describe 'GET issue' do
    def do_request(params={})
      get :issue, { format: 'json', name: 'rainbow' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      it 'creates and returns an oauth token' do
        Timecop.freeze do
          do_request

          auth_token = JSON.parse(response.body)['auth_token']
          expect(AuthToken.verify(auth_token, 'rainbow')).to eq user
        end
      end

      it_behaves_like 'an action that is not cacheable'
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
