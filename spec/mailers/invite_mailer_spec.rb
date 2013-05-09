require 'spec_helper'

describe InviteMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "#send_confirmation" do
    let!(:invite) { create :invite, email: 'naive@user.io', referral_code: 'random_referral_code' }

    it 'sends welcome email after user finished registration' do
      mail = InviteMailer.send_confirmation(invite.id)

      mail.should deliver_to("naive@user.io")
      mail.should deliver_from("Nitrous.IO Team <hello@nitrous.io>")
      mail.should have_subject("Welcome to Nitrous.IO - Your Dev Environment in the Cloud")
    end
  end

  describe "#send_invite" do
    let(:invite)  { create :invite, referral_code: 'random_referral_code' }
    before        { invite.activate! }

    it 'sends accepted invitation email to user' do
      email = InviteMailer.send_invite(invite.id)
      email.should deliver_to(invite.email)
      email.should have_subject("Welcome to Nitrous.IO")
    end

    it 'includes inviting user when the invite is from an user' do
      user = create :user
      invite.inviting_user = user
      invite.save
      email = InviteMailer.send_invite(invite.id)
      email.should have_body_text(user.username)
    end

    context 'when the user is already registered' do
      it 'includes the sign in link' do
        user = create :user
        invite = Invite.find_by_email(user.email)
        email = InviteMailer.send_invite(invite.id)
        email.should have_body_text("/users/sign_in")
        email.should_not have_body_text("/users/sign_up")
      end
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

