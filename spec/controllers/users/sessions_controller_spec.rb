require 'spec_helper'

describe Users::SessionsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::SessionsController' do
    Devise::SessionsController.subclasses.should include Users::SessionsController
  end

  let(:user) { create :user }

  describe '#create' do
    def do_request(params={})
      post :create, { redirect_to: '/app#/boxes' }.merge(params)
    end

    context 'when authenticating normally' do
      before { do_request user: { username: user.username, password: user.password } }

      it { should redirect_to '/app#/boxes' }
      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end
  end

  describe '#create_with_sign_in_token' do
    def do_request(params={})
      get :create_with_sign_in_token, params
    end

    context 'when sign_in_token param is present' do
      let!(:message_verifier) { controller.send :message_verifier }

      context 'when sign_in_token is valid' do
        let(:token) { 'some_sign_in_token' }

        before { SignInToken.stub(:verify).with(token).and_return user }

        context 'when redirect_to param is present' do
          before { do_request redirect_to: '/boxes', sign_in_token: token }

          it { should redirect_to '/boxes' }
          its(:user_signed_in?) { should be_true }
          its(:current_user) { should eq(user) }
        end

        context 'when redirect_to param is absent' do
          before { do_request sign_in_token: token }

          it { should redirect_to root_url }
          its(:user_signed_in?) { should be_true }
          its(:current_user) { should eq(user) }
        end
      end

      context 'when sign_in_token is invalid' do
        let(:token) { 'some_sign_in_token' }

        before { SignInToken.stub(:verify).with(token).and_return nil }

        context 'when redirect_to param is present' do
          before { do_request redirect_to: '/boxes', sign_in_token: token }

          it { should redirect_to new_user_session_url }
          its(:user_signed_in?) { should be_false }
          its(:current_user) { should be_nil }
        end

        context 'when redirect_to param is absent' do
          before { do_request sign_in_token: token }

          it { should redirect_to new_user_session_url }
          its(:user_signed_in?) { should be_false }
          its(:current_user) { should be_nil }
        end
      end
    end

    context 'when sign_in_token param is absent' do
      context 'when redirect_to param is present' do
        before { do_request redirect_to: '/boxes' }

        it { should redirect_to new_user_session_url }
        its(:user_signed_in?) { should be_false }
        its(:current_user) { should be_nil }
      end

      context 'when redirect_to param is absent' do
        before { do_request }

        it { should redirect_to new_user_session_url }
        its(:user_signed_in?) { should be_false }
        its(:current_user) { should be_nil }
      end
    end
  end
end

