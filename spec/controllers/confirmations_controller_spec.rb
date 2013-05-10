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
      response.should be_success
      response.should render_template(:new)
    end
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
      user.username.should eq("iamclovin")
    end

    it 'redirects to home page' do
      do_request
      response.should redirect_to(web_app_path)
    end

    context 'when missing username' do
      it 'render the form again' do
        expect {
          do_request username: ""
        }.to_not change { user.reload.updated_at }
        response.should render_template(:new)
      end
    end

    context 'when missing password' do
      it 'render the form again' do
        expect {
          do_request password: ""
        }.to_not change { user.reload.encrypted_password }
        response.should render_template(:new)
      end
    end
  end
end
