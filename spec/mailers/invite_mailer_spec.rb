require 'spec_helper'

describe InviteMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "#send_collaboration_invite" do
    let!(:user)   { create :user }
    let!(:box)    { create :box, owner: user }
    let!(:invite) { create :collaboration_invite, email: 'naive@user.io', box: box }

    it 'sends a collaboration email to a new user asking him to sign up' do
      mail = InviteMailer.send_collaboration_invite(invite.id)

      mail.should deliver_to("naive@user.io")
      mail.should deliver_from("Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>")
      mail.should have_subject("Nitrous.IO - Invitation to Collaborate and Code with #{user.username}")
    end
  end

  describe "#send_invite" do
    let(:user)    { create :user , username: 'ajhit406' }
    let(:invite)  { create :invite, referral_code: 'random_referral_code', inviting_user_id: user.id }
    before        { invite.activate! }

    it 'sends invitation email to user' do
      email = InviteMailer.send_invite(invite.id)
      email.should deliver_to(invite.email)
      email.should have_subject("#{user.username} invited you to Nitrous.IO")
    end

    it 'includes inviting user when the invite is from an user' do
      user = create :user
      invite.inviting_user = user
      invite.save
      email = InviteMailer.send_invite(invite.id)
      email.should have_body_text(user.username)
    end

    context 'when the user has not registered' do
      before do
        User.where(email: invite.email).destroy_all
      end

      it 'includes the sign up link' do
        email = InviteMailer.send_invite(invite.id)
        email.should_not have_body_text("/users/sign_in")
        email.should have_body_text("/users/sign_up")
      end
    end
  end
end

