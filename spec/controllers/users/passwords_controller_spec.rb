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

    def do_request(email)
      post :create, user: { email: email }, format: 'json'
    end

    context 'with a valid email' do
      it 'should respond with no content' do
        do_request user.email
        expect(controller).to respond_with :created
      end
    end

    context 'with an invalid email' do
      it 'should respond with a 422 unprocessable entity code' do
        do_request 'invalid@user.email'
        expect(controller).to respond_with :unprocessable_entity
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
end
