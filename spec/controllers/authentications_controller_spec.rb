require 'spec_helper'

describe AuthenticationsController do
  describe '#edit' do
    let(:token) { authentication.token }

    def do_request
      get :edit, id: authentication.id, token: token
    end

    context 'when request doesnt have valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication }
      let(:token) { "hack-token" }

      it 'doesnt allow access' do
        expect { do_request }.to raise_error
      end
    end

    context 'when the authentication is confirmed' do
      let(:authentication) { create :authentication }

      it 'redirects to web app' do
        do_request
        response.should redirect_to(web_app_url)
      end
    end

    context 'when request has valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication }

      it 'renders the password confirmation page' do
        do_request
        response.should be_success
        assigns(:authentication).should eq(authentication)
      end
    end
  end

  describe '#update' do
    let(:user) { create :user, password: 'my-password', password_confirmation: 'my-password' }
    let(:token) { authentication.token }
    let(:password) { 'my-password' }

    def do_request
      put :update, id: authentication.id, token: token, user: { password: password }
    end

    context 'when request doesnt have valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication }
      let(:token) { "hack-token" }

      it 'doesnt allow access' do
        expect { do_request }.to raise_error
      end
    end

    context 'when the authentication is confirmed' do
      let(:authentication) { create :authentication }

      it 'returns an error' do
        do_request
        response.should redirect_to(web_app_url)
      end
    end

    context 'when request has valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication, user: user }

      context 'when the password is correct for the authentication user' do
        it 'confirms the authentication' do
          authentication.should_not be_confirmed
          do_request
          authentication.reload.should be_confirmed
          controller.should be_signed_in
          response.should redirect_to(web_app_url)
        end
      end

      context 'when the password is incorrect' do
        let(:password) { "hack-password" }

        it 're-renders the page without signing the user in' do
          do_request
          controller.should_not be_signed_in
          response.should render_template(:edit)
        end
      end
    end
  end
end
