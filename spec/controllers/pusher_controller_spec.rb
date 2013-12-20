require 'spec_helper'

describe PusherController do
  describe 'POST auth' do
    context 'when the channel name starts with private-user-' do
      let!(:user1) { create :user }
      let!(:user2) { create :user }

      def do_request(params={})
        post :auth, { channel_name: "private-user-#{user1.id}", socket_id: 'socket-id' }.merge(params)
      end

      before do
        channel = instance_double('Pusher::Channel')
        Pusher.stub(:[]).with("private-user-#{user1.id}") { channel }
        channel.stub(:authenticate).with('socket-id') { { mock_json: 'response' } }
      end

      context 'when signed in' do
        context "when the channel_name param contains current user's id" do
          before do
            sign_in user1
            do_request
          end

          it { should respond_with :success }
          its('response.body') { should == { mock_json: 'response'}.to_json }
        end

        context "when the channel_name param contains someone else's id" do
          before do
            sign_in user2
            do_request
          end

          it { should respond_with :forbidden }
        end
      end

      context 'when authenticating with oauth2 token with :push scope' do
        let(:token) { double(accessible?: true, resource_owner_id: user1.id, scopes: Doorkeeper::OAuth::Scopes.from_string('push')) }

        before do
          controller.stub(:doorkeeper_token) { token }
          controller.stub(:oauth_token_present?).and_return true
          do_request
        end

        it { should respond_with :success }
        its('response.body') { should == { mock_json: 'response'}.to_json }
      end

      context 'when authenticating with oauth2 token without :push scope' do
        let(:token) { double(accessible?: true, resource_owner_id: user1.id, scopes: Doorkeeper::OAuth::Scopes.from_string('not_push')) }

        before do
          controller.stub(:doorkeeper_token) { token }
          controller.stub(:oauth_token_present?).and_return true
          do_request
        end

        it { should respond_with :unauthorized }
      end

      context 'when not signed in' do
        before { do_request }

        it { should respond_with :forbidden }
      end
    end

    context 'when channel name is not provided' do
      let!(:user) { create :user }

      def do_request(params={})
        post :auth, { socket_id: 'socket_id' }.merge(params)
      end

      before do
        sign_in user
        do_request
      end

      it { should respond_with :forbidden }
    end

    context 'when the socked id is not provided' do
      let!(:user) { create :user }

      def do_request(params={})
        post :auth, { channel_name: "private-user-#{user.id}" }.merge(params)
      end

      before do
        sign_in user
        do_request
      end

      it { should respond_with :forbidden }
    end
  end
end
