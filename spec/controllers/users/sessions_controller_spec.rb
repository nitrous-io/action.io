require 'spec_helper'

describe Users::SessionsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::SessionsController' do
    Devise::SessionsController.subclasses.should include Users::SessionsController
  end

  describe '#create' do
    let!(:user) { create :user, username: 'pete', password: '123456' }

    def do_request(params={})
      post :create, { redirect_to: '/app#/boxes' }.merge(params)
    end

    context 'when authenticating normally' do
      before { do_request user: { username: 'pete', password: '123456' } }

      it { should redirect_to '/app#/boxes' }
      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end

    context 'when authenticating with oauth2 token with :web scope' do
      let(:token) { double(accessible?: true, resource_owner_id: user.id, scopes: [:web]) }

      before do
        controller.stub(:doorkeeper_token) { token }
        controller.stub(:oauth_token_present?).and_return true
        do_request
      end

      it { should redirect_to '/app#/boxes' }
      its(:user_signed_in?) { should be_true }
      its(:current_user) { should eq(user) }
    end

    context 'when authenticating with oauth2 token without :web scope' do
      let(:token) { double(accessible?: true, resource_owner_id: user.id, scopes: [:not_web]) }

      before do
        controller.stub(:doorkeeper_token) { token }
        controller.stub(:oauth_token_present?).and_return true
        do_request
      end

      it { should respond_with :unauthorized }
      its(:user_signed_in?) { should be_false }
      its(:current_user) { should be_nil }
    end
  end
end

