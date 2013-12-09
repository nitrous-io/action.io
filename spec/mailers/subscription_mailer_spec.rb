require 'spec_helper'

describe SubscriptionMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe 'subscription_activated' do
    let!(:user)             { create :user, email: 'granger@hogwarts.edu' }
    let!(:plan)             { create :plan, name: 'Nitro', n2o_amount: 42, price: 9.99 }
    let!(:subscription)     { create :subscription, plan: plan, user: user }

    it 'sends an email to the user informing her that her new subscription is activated' do
      mail = SubscriptionMailer.subscription_activated(subscription.id)

      expect(mail).to deliver_to 'granger@hogwarts.edu'
      expect(mail).to bcc_to 'billing+success@nitrous.io'
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/Nitro/)
      expect(mail).to have_body_text('N2O: 42')
      expect(mail).to have_body_text('USD 9.99')
    end
  end

  describe "payment_failed_alert" do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription)    { create :subscription, user: user }

    it "sends an email to the user informing her that the payment failed" do
      plan = subscription.plan
      mail = SubscriptionMailer.payment_failed_alert subscription.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your subscription payment for '#{plan.name}' has failed")
    end

    it "includes user's current card details" do
      plan = subscription.plan
      mail = SubscriptionMailer.payment_failed_alert subscription.id

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end
  end

  describe "credit_card_changed_alert" do
    let!(:user) { create :user }
    let!(:billing_profile)    { create :billing_profile, user: user }

    it "sends an email to the user informing credit card changed failed" do
      mail = SubscriptionMailer.credit_card_changed_alert user.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your credit card changed")
    end

    it "includes updated card details" do
      mail = SubscriptionMailer.credit_card_changed_alert user.id

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end
  end

  describe "credit_card_expiring_alert" do
    let!(:billing_profile)    { create :billing_profile }

    it "sends an email to the user informing credit card is expiring" do
      user = billing_profile.user
      mail = SubscriptionMailer.credit_card_expiring_alert billing_profile

      expect(mail).to deliver_to user.email
      expect(mail).to bcc_to "billing+expiries@nitrous.io"
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("[Action required] Your credit card will expire this month")
    end

    it "includes current card details" do
      user = billing_profile.user
      mail = SubscriptionMailer.credit_card_expiring_alert billing_profile

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end
  end

end
