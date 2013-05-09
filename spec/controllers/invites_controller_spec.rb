require 'spec_helper'

describe InvitesController do
  describe "GET index" do
    let(:user) { create :user }
    let(:invite) { create :invite, inviting_user: user }
    let(:another_invite) { create :invite }

    def do_request
      get :index
    end

    it 'gets all invites from the current user' do
      sign_in user
      do_request
      assigns(:invites).should eq([invite])
      response.should be_success
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe "POST create" do
    let(:user) { create :user }
    let(:invite) { create :invite }
    let(:user_invitation) { stub(invite: false) }

    def do_request(email="test@email.com")
      post :create, invite: { email: email }
    end

    context 'when the user is signed in' do
      before do
        sign_in user
        UserInvitation.stub(:new) { user_invitation }
      end

      it 'creates an invitation' do
        user_invitation.should_receive(:invite).with("test@email.com") { invite }
        do_request "test@email.com"
        response.should redirect_to(invites_path)
        assigns(:invite).should eq(invite)
        flash[:notice].should=~ /Invite has been sent to #{invite.email}/
      end

      it 'fails when the user cannot invite anyone' do
        user_invitation.stub(:invite) { UserInvitation::NO_INVITE_LEFT }
        do_request
        flash[:notice].should=~ /Looks like you don't have any invites left/
      end

      it 'fails when the invites cannot be saved' do
        invalid_invite = Invite.new
        invalid_invite.should_not be_valid
        user_invitation.stub(:invite) { invalid_invite }
        do_request
        flash[:notice].should=~ /Looks like you entered an invalid invite, please try again/
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
