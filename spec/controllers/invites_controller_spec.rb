require 'spec_helper'

describe InvitesController do
  let!(:user) { create :user }
  let!(:invite) { create :invite, inviting_user: user }
  let!(:another_invite) { create :invite }

  describe "GET index" do
    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it 'gets all invites from the current user' do
        assigns(:invites).should eq([invite])
        response.body.should == { invites: assigns(:invites).serialize_as_hash }.to_json
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe "POST create" do
    let(:user_invitation) { stub(invite: false) }

    def do_request(email="test@email.com")
      post :create, { format: 'json', invite: { email: email } }
    end

    context 'when the user is signed in' do
      before do
        sign_in user
        UserInvitation.stub(:new) { user_invitation }
      end

      context 'valid invitation request' do
        before do
          user_invitation.should_receive(:invite).with("test@email.com") { invite }
          do_request "test@email.com"
        end

        it { should respond_with :created }
        its('response.body') { should == invite.serialize_as_json }
      end

      context 'when the user cannot invite anyone' do
        before do
          user_invitation.stub(:invite) { UserInvitation::NO_INVITE_LEFT }
          do_request
        end

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { error: 'no invites left' }.to_json }
      end

      context 'when the invite request is invalid' do
        before do
          invalid_invite = Invite.new
          invalid_invite.should_not be_valid
          user_invitation.stub(:invite) { invalid_invite }
          do_request
        end

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { error: 'invalid invite request' }.to_json }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
