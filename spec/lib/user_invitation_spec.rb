require 'spec_helper'

describe UserInvitation do
  let(:user) { mock_model(User) }
  let(:user_invitation) { described_class.new user }

  describe "#invite" do
    it 'does not send invite when the user does not have any invitation left' do
      user.stub(:able_to_invite?) { false }
      expect {
        result = user_invitation.invite("test@email.com")
        result.should eq(UserInvitation::NO_INVITE_LEFT)
      }.to_not change { Delayed::Job.count }
    end

    context 'when the user still has unused invitation' do
      let(:invite) { mock_model(Invite) }

      before do
        user.stub(:able_to_invite?) { true }
        invite.stub(:activated?) { true }
      end

      context "when user has invited this email before" do
        before do
          user.should_receive(:owned_invite_with_email).with("test@email.com") { invite }
        end

        it 'does not create a new invitation' do
          user_invitation.should_not_receive(:new_invite)
          user_invitation.invite("test@email.com")
        end

        it 'sends invitation email' do
          expect {
            user_invitation.invite("test@email.com")
          }.to change { Delayed::Job.count }
          InviteMailer.should_receive(:send_invite).with(invite.id) { stub.as_null_object }
          Delayed::Job.last.invoke_job
        end
      end

      context "when user has never invited this email before" do
        before do
          user.stub(:owned_invite_with_email) { nil }
          user_invitation.stub(:new_invite) { invite }
        end

        it 'creates a new invitation' do
          user_invitation.should_receive(:new_invite).with("test@email.com") { invite }
          user_invitation.invite("test@email.com")
        end

        it 'sends invitation email' do
          expect {
            user_invitation.invite("test@email.com")
          }.to change { Delayed::Job.count }
          InviteMailer.should_receive(:send_invite).with(invite.id) { stub.as_null_object }
          Delayed::Job.last.invoke_job
        end

        it 'does not send invitation email when invite was not activated' do
          invite.stub(:activated?) { false }
          expect {
            user_invitation.invite("test@email.com")
          }.to_not change { Delayed::Job.count }
        end
      end
    end
  end

  describe "#new_invite" do
    let(:user) { create :user }

    it 'creates a new activated invitation for the email' do
      invite = user_invitation.new_invite "test@email.com"
      invite.inviting_user.should eq(user)
      invite.should be_persisted
      invite.should be_activated
    end

    it 'does not try to activate when the new invite is invalid' do
      invite = user_invitation.new_invite "test        @email.com"
      invite.should_not be_activated
    end
  end
end
