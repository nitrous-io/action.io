require 'spec_helper'

describe Api::V0::UsersController do
  let(:user) { create :user }

  describe 'GET show' do
    def do_request
      get :show, format: 'json'
    end

    context 'with valid access token' do
      let(:token) { double(accessible?: true, resource_owner_id: user.id, scopes: [:user]) }

      before do
        controller.stub(:doorkeeper_token) { token }
        do_request
      end

      it { should respond_with :success }
      its('response.body') { should == user.serialize_as_json }
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :user
  end
end
