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

    before do
      request.env.merge!(
        'omniauth.auth' => {
          'provider' => 'github',
          'uid' => '123456',
          'info' => {
            'email' => 'test@example.com',
            'name'  => 'John Doe',
            'nickname' => 'johndoe'
          },
          'extra' => {
            'foo' => 'bar'
          }
        }
      )
    end

    context 'when a matching authentication is not found' do
      it 'creates an authentication object' do
        expect {
          do_request
        }.to change { Authentication.count }.by 1
        authentication = Authentication.last
        authentication.provider.should == 'github'
        authentication.uid.should == '123456'
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
    end

    context 'when a matching authentication is found' do
      let!(:authentication) { create :authentication, provider: 'github', uid: '123456' }

      it 'does not create a new authentication object' do
        expect {
          do_request
        }.not_to change { Authentication.count }.by 1
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

