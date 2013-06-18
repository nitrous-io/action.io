require 'spec_helper'

describe UserMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "welcome" do
    it 'sends welcome email after user finished registration' do
      mail = UserMailer.welcome "naive@user.io"

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Getting Started on Nitrous.IO")
    end
  end

  describe "n2o_bonus_alert" do
    let!(:user)     { create :user, email: 'naive@user.io' }
    let!(:n2o_fill) { create :n2o_fill, kind: N2oFill::Kind::INVITING_USER_BONUS, description: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, amount: 10, user: user }

    it "sends an email to the user who's account received N2O fills" do
      mail = UserMailer.n2o_bonus_alert n2o_fill.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/10 units of N2O/)
    end
  end
end
