require 'spec_helper'

describe Api::V0::UsersController do
  let(:user) { create :user }

  describe 'GET show' do
    def do_request
      get :show, format: 'json'
    end

    context 'with valid access token' do
      let(:token) { double accessible?: true, resource_owner_id: user.id, scopes: Doorkeeper::OAuth::Scopes.from_string('user') }

      before do
        controller.stub(:doorkeeper_token) { token }
        TrackMixpanelEventJob.should_receive(:submit_job).with('User Signed In', user.id, {})

        do_request
      end

      it { should respond_with :success }
      its('response.body') { should eq(user.serialize_as_json scope: user) }
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :user
  end

  describe 'GET sign_in_token' do
    def do_request
      get :sign_in_token, format: 'json'
    end

    context 'with valid access token' do
      let(:token) { double accessible?: true, resource_owner_id: user.id, scopes: Doorkeeper::OAuth::Scopes.from_string('web') }

      before do
        controller.stub(:doorkeeper_token) { token }
        do_request
      end

      it { should respond_with :success }

      it 'returns a sign_in_token, which can be used to sign in to action website within the next 5 minutes' do
        Timecop.freeze do
          expect(response.body).to eq({sign_in_token: AuthToken.generate(user, 'sign_in')}.to_json)
        end
      end

      it_behaves_like 'an action that is not cacheable'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :web
  end
end
