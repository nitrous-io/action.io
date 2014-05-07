require 'spec_helper'

describe Oauth::TokensController do
  let(:user) { create :user, password: '123456' }
  let(:oauth_app) { Doorkeeper::Application.create name: 'AwesomeApp', redirect_uri: 'http://example.com' }

  describe 'POST create' do
    def do_request
      post :create, format: 'json', client_id: oauth_app.uid, client_secret: oauth_app.secret, grant_type: 'password', username: user.username, password: '123456' , scope: 'public boxes push web user'
    end

    context 'when password is correct' do
      it 'returns the access token along with resource_owner_id' do
        expect {
          do_request
        }.to change { Doorkeeper::AccessToken.count }.by 1

        expect(controller).to respond_with :ok

        access_token = Doorkeeper::AccessToken.last
        body = JSON.parse(controller.response.body)
        expect(body['token_type']).to eq 'bearer'
        expect(body['access_token']).to eq access_token.token
        expect(body['scope']).to eq 'public boxes push web user'
        expect(body['resource_owner_id']).to eq user.id
      end
    end

    context 'when password is incorrect' do
      before do
        user.password = 'foobar'
        user.password_confirmation = 'foobar'
        user.save!
      end

      it 'does not return access token' do
        expect {
          do_request
        }.not_to change { Doorkeeper::AccessToken.count }
      end
    end
  end
end
