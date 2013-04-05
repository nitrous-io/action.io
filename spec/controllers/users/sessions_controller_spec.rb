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
      post :create, ({ user: { login: user.username, password: user.password }}).merge(params)
    end

    def do_request_with_email(params={})
      post :create, ({ user: { login: user.email, password: user.password }}).merge(params)
    end

    context 'when redirect_to param exists' do
      before { do_request redirect_to: '/app#/boxes' }

      it { should redirect_to 'http://test.host/app#/boxes' }
      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end

    context 'when redirect_to param contains url to another host' do
      before { do_request redirect_to: 'http://www.google.com/foo/bar?hello=world&foo=bar#/boxes/1/lol' }

      it 'should not redirect to another host' do
        expect(controller).to redirect_to 'http://test.host/foo/bar?hello=world&foo=bar#/boxes/1/lol'
      end

      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end

    context "login with email" do
      before { do_request_with_email redirect_to: '/app#/boxes' }

      it { should redirect_to 'http://test.host/app#/boxes' }
      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end
  end

  describe '#create_with_sign_in_token' do
    def do_request(params={})
      get :create_with_sign_in_token, params
    end

    context 'when sign_in_token param is present' do
      context 'when sign_in_token is valid' do
        let(:token) { 'some_sign_in_token' }

        before { AuthToken.stub(:verify).with(token, 'sign_in').and_return user }

        context 'when redirect_to param is present' do
          before { do_request redirect_to: '/boxes', sign_in_token: token }

          it { should redirect_to 'http://test.host/boxes' }
          its(:user_signed_in?) { should be_true }
          its(:current_user) { should eq(user) }
        end

        context 'when redirect_to param contains url to another host' do
          before { do_request redirect_to: 'http://www.apple.com/foo', sign_in_token: token }

          it 'should not redirect to another host' do
            expect(controller).to redirect_to 'http://test.host/foo'
          end

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

        before { AuthToken.stub(:verify).with(token, 'sign_in').and_return nil }

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

