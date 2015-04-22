require 'spec_helper'

describe ConfirmationsController do
  describe 'GET new' do
    let(:user) { create :external_authenticated_user }
    before { sign_in user}

    def do_request
      get :new , user_id: user.id
    end

    it 'renders the confirmation page' do
      do_request
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    context 'when authentications data has username' do
      before do
        create :authentication, user: user, username: "hahaha"
        create :authentication, user: user
      end

      it 'presets username of current_user to authentications username' do
        do_request
        expect(controller.current_user.username).to eq("hahaha")
      end
    end

    it_behaves_like "an action that redirects valid logged-in user"
  end

  describe 'PUT create' do
    let(:user) { create :external_authenticated_user }
    before { sign_in user}

    def do_request(opts={})
      post :create, user: { username: 'iamclovin', password: 'new-password' }.merge(opts)
    end

    it 'updates user information' do
      expect {
        do_request
      }.to change {user.reload.encrypted_password }
      expect(user.username).to eq("iamclovin")
    end

    context 'when a "hack" cookie is present' do
      it 'redirects to the path present in cookie' do
        request.cookies[:hack] = '/some/path%3Frepo%3Dnitrous-io/autoparts'
        do_request
        expect(response).to redirect_to('/some/path%3Frepo%3Dnitrous-io/autoparts')
      end
    end

    context 'when a "hack" cookie is not present' do
      it 'redirects to home page' do
        do_request
        expect(response).to redirect_to(web_app_path)
      end
    end

    context 'when missing username' do
      it 'render the form again' do
        expect {
          do_request username: ""
        }.to_not change { user.reload.updated_at }
        expect(response).to render_template(:new)
      end
    end

    context 'when missing password' do
      it 'render the form again' do
        expect {
          do_request password: ""
        }.to_not change { user.reload.encrypted_password }
        expect(response).to render_template(:new)
      end
    end

    it_behaves_like "an action that redirects valid logged-in user"
  end

  describe 'DELETE destroy' do
    let(:user) { create :external_authenticated_user }
    before { sign_in user}

    def do_request
      delete :destroy
    end

    it 'logs out current user' do
      do_request
      expect(controller.current_user).not_to be_present
      expect(response).to redirect_to("https://lite.nitrous.io/")
    end

    it 'removes current user and associated authentications' do
      do_request
      user_id = user.id
      expect(User.where(id: user_id)).not_to be_present
      expect(Authentication.where(user_id: user_id)).to be_empty
    end

    it_behaves_like "an action that redirects valid logged-in user"
  end
end
