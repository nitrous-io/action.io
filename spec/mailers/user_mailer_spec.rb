require 'spec_helper'

describe UserMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "n2o_bonus_alert" do
    let!(:user)     { create :user, email: 'naive@user.io' }
    let!(:n2o_fill) { create :n2o_fill, kind: N2oFill::Kind::INVITING_USER_BONUS, description: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, amount: 10, user: user }

    it "sends an email to the user whose account received N2O fills" do
      mail = UserMailer.n2o_bonus_alert n2o_fill.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/10 units of N2O/)
    end
  end

  describe "n2o_purchased_alert" do
    let!(:user)             { create :user, email: 'naive@user.io' }
    let!(:subscription_plan) { create :subscription_plan }
    let!(:billing_profile)  { create :billing_profile, user: user, plan: subscription_plan }
    let!(:subscription)     { create :subscription, billing_profile: billing_profile, subscription_plan: subscription_plan }
    let!(:n2o_fill) { create :n2o_fill, kind: N2oFill::Kind::PURCHASE, amount: 100, user: user, resource: subscription }

    it "sends an email to the user who purchased N2O" do
      mail = UserMailer.n2o_purchased_alert n2o_fill.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/100 units of N2O/)
    end
  end

  describe "private_beta_thanks" do
    let!(:user)     { create :user, email: 'naive@user.io' }

    it "sends a thank you note to a user" do
      mail = UserMailer.private_beta_thanks user.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/is now open to all/)
    end
  end

  describe "box_memory_limit_hit_alert" do
    let!(:user)     { create :user, email: 'naive@user.io' }
    let!(:box)      { create :box, owner: user }

    it "sends an alert notifying the user that the box has hit its memory limits" do
      mail = UserMailer.box_memory_hit_limit_alert box.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match"You seem to have hit memory limits on your Nitrous.IO box - #{box.name}"
      expect(mail.body).to match(/upgrade the memory/)
    end
  end

  describe "confirmation_reminder_1" do
    let!(:user)     { create :unconfirmed_user, email: 'naive@user.io' }

    it "sends confirmation reminder to a user" do
      mail = UserMailer.confirmation_reminder_1 user.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from 'AJ Solimine <ajs@nitrous.io>'
      expect(mail.subject).to match(/Activate Your Nitrous.IO Account/)
      expect(mail).to have_body_text(user.confirmation_token)
    end
  end

  describe "confirmation_reminder_2" do
    let!(:user)     { create :unconfirmed_user, email: 'naive@user.io' }

    it "sends confirmation reminder to a user" do
      mail = UserMailer.confirmation_reminder_2 user.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from 'Greg <support@nitrous.io>'
      expect(mail.subject).to match(/Activate Your Nitrous.IO Account/)
      expect(mail).to have_body_text(user.confirmation_token)
    end
  end

  describe "confirmation_reminder_3" do
    let!(:user)     { create :unconfirmed_user, email: 'naive@user.io' }

    it "sends confirmation reminder to a user" do
      mail = UserMailer.confirmation_reminder_3 user.id

      expect(mail).to deliver_to "naive@user.io"
      expect(mail).to deliver_from 'Nitrous.IO <hello@nitrous.io>'
      expect(mail.subject).to match(/Your Nitrous.IO Account is waiting/)
      expect(mail).to have_body_text(user.confirmation_token)
    end
  end
end
