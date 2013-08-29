require 'spec_helper'

describe SubscriptionMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "payment_failed_alert" do
    let!(:subscription)    { create :subscription }

    it "sends an email to the user informing the payment failed" do
      user = subscription.billing_profile.user
      plan = subscription.subscription_plan
      mail = SubscriptionMailer.payment_failed_alert subscription.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your subscription payment for '#{plan.name}' has failed")
    end

    it "includes user's current card details" do
      billing_profile = subscription.billing_profile
      user = subscription.billing_profile.user
      plan = subscription.subscription_plan
      mail = SubscriptionMailer.payment_failed_alert subscription.id

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end
  end

  describe "subscription_activation_alert" do
    let!(:subscription_plan)  { create :subscription_plan, price: 5.0 }
    let!(:subscription)       { create :subscription, subscription_plan: subscription_plan }

    it "sends an email to the user informing subscription activated" do
      user = subscription.billing_profile.user
      plan = subscription.subscription_plan
      mail = SubscriptionMailer.subscription_activation_alert subscription.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your account was upgraded to '#{plan.name}' plan")
    end

    it "includes user's current card and plan details" do
      billing_profile = subscription.billing_profile
      user = subscription.billing_profile.user
      plan = subscription.subscription_plan
      mail = SubscriptionMailer.subscription_activation_alert subscription.id

      expect(mail).to have_body_text("You will be charged USD 5.00 every #{plan.interval}.")
      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end

  end
end
