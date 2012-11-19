require 'spec_helper'

describe UserInvitation do
  let(:user) { mock_model(User) }
  let(:user_invitation) { described_class.new user }

  describe "#invite" do
    context 'when the user does not have any invitation left' do
      before { user.stub(:able_to_invite?) { false } }

      it 'does not send invite' do
        expect {
          result = user_invitation.invite("test@email.com")
          result.should eq(UserInvitation::NO_INVITE_LEFT)
        }.to_not change { Delayed::Job.count }
      end
    end

    context 'when the user still has unused invitation' do
      before { user.stub(:able_to_invite?) { true } }

      context "when invitee has never requested for invitation before" do
        let(:invite) { mock_model(Invite) }

        before do
          Invite.should_receive(:for_email).with("test@email.com") { nil }
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
          Notifier.should_receive(:send_invite).with(invite.id) { stub.as_null_object }
          Delayed::Job.last.invoke_job
        end

        context "when invite is not valid" do
          before { invite.stub(:valid?) { false } }

          it 'does not send invitation email' do
            expect {
              user_invitation.invite("test@email.com")
            }.to_not change { Delayed::Job.count }
          end
        end
      end

      context "when invitee has requested for invitation" do
        let(:invite) { mock_model(Invite) }

        before { Invite.should_receive(:for_email).with("test@email.com") { invite } }

        it 'does not create a new invitation' do
          user_invitation.should_not_receive(:new_invite)
          user_invitation.invite("test@email.com")
        end

        it 'sends invitation email' do
          expect {
            user_invitation.invite("test@email.com")
          }.to change { Delayed::Job.count }
          Notifier.should_receive(:send_invite).with(invite.id) { stub.as_null_object }
          Delayed::Job.last.invoke_job
        end
      end
    end
  end

  describe "#new_invite" do
    let(:user) { create :user }

    it 'creates a new invitation for the email' do
      invite = user_invitation.new_invite "test@email.com"
      invite.inviting_user.should eq(user)
      invite.should be_persisted
    end

    it 'sends confirmation email' do
      invite = user_invitation.new_invite("test@email.com")
      Notifier.should_receive(:invite_confirmation).with(invite.id) { stub.as_null_object }
      Delayed::Job.last.invoke_job
    end

    context 'when the invite is invalid' do
      it 'does not send confirmation email' do
        expect {
          user_invitation.new_invite("")
        }.to_not change { Delayed::Job.count }
      end
    end
  end
end
