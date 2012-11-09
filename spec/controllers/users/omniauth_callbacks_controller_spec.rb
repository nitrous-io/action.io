require 'spec_helper'

describe Users::OmniauthCallbacksController do
  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe '#github' do
    let(:user) { create :user }

    def do_request
      get :github
    end

    let!(:omniauth_hash) do
      {
        'provider' => 'github',
        'uid' => '123456',
        'info' => {
          'email' => 'test@example.com',
          'name'  => 'John Doe',
          'nickname' => 'johndoe'
        },
        'credentials' => {
          'token' => 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        },
        'extra' => {
          'foo' => 'bar'
        }
      }
    end

    before { request.env.merge!('omniauth.auth' => omniauth_hash) }

    it 'fails when user is not logged in' do
      do_request
      response.should_not be_success
    end

    context 'when user is logged in already' do
      before { sign_in user }
      context 'when a matching authentication is not found' do
        it 'creates a new authentication' do
          expect {
            do_request
          }.to change { user.reload.authentications.count }.by(1)
          user.authentications.last.provider.should eq('github')
          user.authentications.last.uid.should eq('123456')
        end
      end

      context 'when a matching authentication is found' do
        let!(:authentication) {
          create(:authentication, provider: 'github',
                 uid: '123456', token: 'ff43201c98ffb1978c79587733e5f59a696c2a2a',
                 user: user)
        }

        it 'does not create new authentication' do
          expect {
            do_request
          }.to_not change { user.reload.authentications.count }
        end

        it 'updates authentication object with new token' do
          do_request
          authentication.reload.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
        end
      end
    end
  end
end
