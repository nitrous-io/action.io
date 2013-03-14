require 'spec_helper'

describe VagrantController do
  let(:user) { create :user }
  let!(:vagrant_app) { Doorkeeper::Application.create name: 'Vagrant', redirect_uri: 'http://example.com' }

  describe 'GET access_token' do
    def do_request
      get :access_token, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when vagrant oauth token for current user does not exist' do
        it 'creates and returns an oauth token' do
          expect {
            do_request
          }.to change { Doorkeeper::AccessToken.count }.by(1)

          token = Doorkeeper::AccessToken.last
          expect(token.resource_owner_id).to eq user.id
          expect(token.application).to eq vagrant_app
          expect(token.scopes.to_s).to eq 'public boxes'
          expect(token.token).not_to be_blank

          expect(response.body).to eq({
            access_token: token.token
          }.to_json)
        end
      end

      context 'when vagrant oauth token for current user exists' do
        let!(:token) do
          Doorkeeper::AccessToken.create(resource_owner_id: user.id, application_id: vagrant_app.id, scopes: 'public boxes')
        end

        it 'returns existing oauth token' do
          expect {
            do_request
          }.not_to change { Doorkeeper::AccessToken }

          expect(response.body).to eq({
            access_token: token.token
          }.to_json)
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
