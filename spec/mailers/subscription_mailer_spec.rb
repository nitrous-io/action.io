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
end
