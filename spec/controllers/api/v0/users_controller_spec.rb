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
      its('response.body') { should eq(user.serialize_as_json) }
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :user
  end

  describe 'GET sign_in_token' do
    def do_request
      get :sign_in_token, format: 'json'
    end

    context 'with valid access token' do
      let(:token) { double(accessible?: true, resource_owner_id: user.id, scopes: [:web]) }

      before do
        controller.stub(:doorkeeper_token) { token }
        Timecop.freeze
        do_request
      end

      after { Timecop.return }

      it { should respond_with :success }

      it 'returns a sign_in_token, which can be used to sign in to action website within the next 5 minutes' do
        expiry_time = Time.now + 5.minutes
        expected_token = [user.id, expiry_time.to_i]
        expected_token = controller.send(:message_verifier).generate expected_token
        expect(response.body).to eq({sign_in_token: expected_token}.to_json)
      end
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :web
  end
end
