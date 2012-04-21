require 'spec_helper'

describe Users::OmniauthCallbacksController do
  it 'is a subclass of Devise::OmniauthCallbacksController' do
    Devise::OmniauthCallbacksController.subclasses.should include Users::OmniauthCallbacksController
  end

  before { request.env['devise.mapping'] = Devise.mappings[:user] }

  describe '#passthru' do
    it 'returns 404' do
      get :passthru
      response.code.should == '404'
    end
  end

  describe '#github' do
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

    context 'when a matching authentication is not found' do
      it 'creates an authentication object' do
        expect {
          do_request
        }.to change { Authentication.count }.by 1
        authentication = Authentication.last
        authentication.provider.should == 'github'
        authentication.uid.should == '123456'
        authentication.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      end

      it 'creates a user object' do
        expect {
          do_request
        }.to change { User.count }.by 1
        user = User.last
        user.authentications.should have(1).authentication
        user.authentications.first.should == Authentication.last
        user.full_name.should == 'John Doe'
      end

      it 'signs in' do
        do_request
        flash[:notice].should match /with GitHub/
        controller.user_signed_in?.should be_true
        controller.current_user.should == User.last
      end

      context 'when some required fields are not found' do
        before do
          request.env['omniauth.auth']['info'].except!('name', 'nickname')
          do_request
        end

        it { should redirect_to new_user_registration_url omniauth: '1', required_fields: 'username full_name' }

        it 'stores the omniauth hash in the session' do
          session['devise.omniauth_hash'].should == omniauth_hash.except('extra')
        end
      end
    end

    context 'when a matching authentication is found' do
      let!(:authentication) { create :authentication, provider: 'github', uid: '123456', token: 'ff43201c98ffb1978c79587733e5f59a696c2a2a' }

      it 'does not create a new authentication object' do
        expect {
          do_request
        }.not_to change { Authentication.count }.by 1
      end

      it 'updates authentication object with new token' do
        do_request
        authentication.reload.token.should == 'b27e7786caf89a6373a3799fa9a57e4558dc2363'
      end

      it 'does not create a new user object' do
        expect {
          do_request
        }.not_to change { User.count }.by 1
      end

      it 'signs in as the user in the matching authentication object' do
        do_request
        flash[:notice].should match /with GitHub/
        controller.user_signed_in?.should be_true
        controller.current_user.should == authentication.user
      end
    end
  end
end

