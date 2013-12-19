require 'spec_helper'

describe AuthenticationsController do
  describe 'GET edit' do
    let(:authentication) { create :authentication }
    let(:token) { authentication.token }
    let(:user) { authentication.user }

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
        expect(response).to redirect_to('/app#/n2o/bonus')
      end
    end

    context 'when request has valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication }

      it 'renders the password confirmation page' do
        do_request
        expect(response).to be_success
        expect(assigns(:authentication)).to eq(authentication)
      end
    end
  end

  describe 'PUT update' do
    let(:user) { create :user, password: 'my-password', password_confirmation: 'my-password' }
    let(:authentication) { create :authentication }
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
        expect(response).to redirect_to('/app#/n2o/bonus')
      end
    end

    context 'when request has valid authentication token' do
      let(:authentication) { create :unconfirmed_authentication, user: user }

      context 'when the password is correct for the authentication user' do
        it 'confirms the authentication' do
          expect(authentication).not_to be_confirmed
          do_request
          expect(authentication.reload).to be_confirmed
          expect(controller).to be_signed_in
          expect(response).to redirect_to('/app#/n2o/bonus')
        end
      end

      context 'when the password is incorrect' do
        let(:password) { "hack-password" }

        it 're-renders the page without signing the user in' do
          do_request
          expect(controller).not_to be_signed_in
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  describe 'DELETE destroy' do
    let!(:authentication) { create :unconfirmed_authentication }
    let(:user) { authentication.user }
    let(:token) { authentication.token }

    def do_request
      delete :destroy, id: authentication.id, token: token
    end

    it 'removes current authentication with the specified token' do
      expect {
        do_request
      }.to change { Authentication.count }.by(-1)
      expect(Authentication.where(id: authentication.id)).to be_empty
      expect(response).to redirect_to(root_path)
    end

    context 'when the token is invalid' do
      let(:token) { "hack-token" }

      it 'does not remove the authentication' do
        expect { do_request }.to raise_error
        expect(Authentication.where(id: authentication.id)).not_to be_empty
      end
    end
  end
end
