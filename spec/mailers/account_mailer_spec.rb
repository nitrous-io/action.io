require 'spec_helper'

describe AccountMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "confirmation_instructions" do
    context 'when a new user signs up for an account' do
      let!(:user)     { create :unconfirmed_user }

      it "sends an email which says to confirm the email to start using the app" do
        mail = AccountMailer.confirmation_instructions user, 'token'

        expect(mail).to deliver_to user.email
        expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
        expect(mail.subject).to match(/Confirm your email to start using/)
      end
    end

    context 'when an exisiting user changes her email' do
      let!(:user)     { create :reconfirmed_user }

      it "sends an email which says to confirm the email change" do
        mail = AccountMailer.confirmation_instructions user, 'token', { to: user.unconfirmed_email }

        expect(mail).to deliver_to user.unconfirmed_email
        expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
        expect(mail.subject).to match("Confirm your new Nitrous.IO email address")
      end
    end
  end

end
