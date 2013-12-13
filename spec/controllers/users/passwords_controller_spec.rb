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

    def do_request(reset_password_token)
      get :edit, reset_password_token: reset_password_token
    end

    before do
      user.send_reset_password_instructions
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request user.reset_password_token
      end

      it { should render_template 'edit' }
      it { should respond_with :success }
    end

    context 'when not signed in' do
      before do
        do_request user.reset_password_token
      end

      it { should render_template 'edit' }
      it { should respond_with :success }
    end
  end

  describe '#update' do
    let!(:user) { create :user }

    def do_request(password='passwordz', password_confirmation='passwordz')
      put :update, user: { reset_password_token:user.reset_password_token, password: password, password_confirmation: password_confirmation }
    end

    before do
      user.send_reset_password_instructions
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it 'should redirect the user to the web app' do
        response.should redirect_to web_app_path
      end
    end

    context 'when not signed in' do
      before do
        do_request
      end

      it 'should redirect the user to the web app' do
        response.should redirect_to web_app_path
      end
    end
  end
end
