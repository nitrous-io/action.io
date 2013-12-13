require 'spec_helper'

describe Users::PasswordsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::PasswordsController' do
    expect(Devise::PasswordsController.subclasses).to include Users::PasswordsController
  end

  describe '#create' do
    let!(:user) { create :user }

    context 'when client makes an AJAX request (ie. non-navigational format)' do
      it 'should respond with no content' do
        post :create, user: { email: user.email }, format: 'json'
        expect(controller).to respond_with :created
      end
    end
  end

  describe '#edit' do
    let!(:user) { create :user }

    context 'when signed in' do
      before do
        sign_in user
        user.send_reset_password_instructions
        get :edit, reset_password_token: user.reset_password_token
      end

      it { should render_template 'edit' }
      it { should respond_with :success }
    end
  end

  describe '#update' do
    let!(:user) { create :user }

    context 'when signed in' do
      before do
        user.send_reset_password_instructions
        sign_in user
        put :update, user: { reset_password_token:user.reset_password_token, password: 'password123', password_confirmation: 'password123' }
      end

      it 'should redirect the user to the web app' do
        response.should redirect_to web_app_path
      end
    end
  end
end
