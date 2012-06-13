require 'spec_helper'

describe PusherController do
  describe 'POST auth' do
    context 'when the channel name starts with private-user-' do
      let!(:user1) { create :user_with_invite }
      let!(:user2) { create :user_with_invite }

      def do_request(params={})
        post :auth, { channel_name: "private-user-#{user1.id}", socket_id: 'socket-id' }.merge(params)
      end

      before do
        channel = double(:channel)
        Pusher.stub!(:[]).with("private-user-#{user1.id}") { channel }
        channel.stub!(:authenticate).with('socket-id') { { mock_json: 'response' } }
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

      context 'when not signed in' do
        before { do_request }

        it { should respond_with :forbidden }
      end
    end
  end
end
