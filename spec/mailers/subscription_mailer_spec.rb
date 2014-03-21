require 'spec_helper'

describe SubscriptionMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe 'subscription_activated' do
    let!(:user)         { create :user, email: 'granger@hogwarts.edu' }
    let!(:plan)         { create :plan, name: 'Nitro', n2o_amount: 42, price: 9.99 }
    let!(:subscription) { create :subscription, plan: plan, user: user }

    it 'sends an email to the user informing her that her new subscription is activated' do
      mail = SubscriptionMailer.subscription_activated(subscription.id)

      expect(mail).to deliver_to 'granger@hogwarts.edu'
      expect(mail).to bcc_to 'billing+success@nitrous.io'
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/Nitro/)
      expect(mail).to have_body_text('N2O: 42')
    end
  end

  describe 'subscription_canceled' do
    let!(:user)         { create :user, email: 'granger@hogwarts.edu' }
    let!(:plan)         { create :plan, name: 'Nitro' }
    let!(:subscription) { create :subscription, plan: plan, user: user }

    it 'sends an email to the user informing her that her subscription has been canceled' do
      mail = SubscriptionMailer.subscription_canceled(subscription.id)

      expect(mail).to deliver_to 'granger@hogwarts.edu'
      expect(mail).to bcc_to 'billing@nitrous.io'
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail.subject).to match(/Nitro/)
      expect(mail).to have_body_text('Nitro')
    end
  end

  describe "payment_failed_alert" do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription)    { create :subscription, user: user }

    def do_action(attempt_count=1, amount_due=1000, billing_period='Mar 05, 2014 - Apr 05, 2014')
      SubscriptionMailer.payment_failed_alert subscription.id, attempt_count: attempt_count, amount_due: amount_due, billing_period: billing_period
    end

    it 'sends an email to the user informing her that the payment failed' do
      plan = subscription.plan
      mail = do_action

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your subscription payment for '#{plan.name}' has failed")
    end

    it "includes amount due, billing period and user's current card details" do
      plan = subscription.plan
      mail = do_action

      expect(mail).to have_body_text("USD10.00")
      expect(mail).to have_body_text('Mar 05, 2014 - Apr 05, 2014')

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
    end

    context "when it's not the final notice" do
      it 'should say which notice it is in the subject' do
        mail = do_action 2
        expect(mail).to have_subject(/2nd Notice/)
      end
    end

    context "when it's the final notice" do
      it "should say it's the final notice in the subject" do
        mail = do_action 3
        expect(mail).to have_subject(/Final Notice/)
      end

      it "should mention it's the final notice in the body" do
        mail = do_action 3
        expect(mail).to have_body_text('This will be your final notice')
      end
    end

    context "when the attempt count is zero (manually attempting the invoice)" do
      it "should not say anything about the attempt in the subject" do
        plan = subscription.plan
        mail = do_action 0
        expect(mail).to have_subject("Your subscription payment for '#{plan.name}' has failed")
      end

      it "should mention it's the final notice in the body" do
        mail = do_action 3
        expect(mail).to have_body_text('This will be your final notice')
      end
    end

    context "when the method is called with missing params" do
      it 'should raise an error' do
        expect { SubscriptionMailer.payment_failed_alert subscription.id }.to raise_error
      end
    end
  end

  describe "delinquency_alert" do
    let!(:user) { create :user }
    let!(:subscription)    { create :subscription, user: user }

    def do_action(attempt_count=1, amount_due=1000, billing_period='Mar 05, 2014 - Apr 05, 2014')
    end

    it 'sends an email to the user informing her that the account is delinquent' do
      plan = subscription.plan
      mail = SubscriptionMailer.delinquency_alert user.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Delinquency Notice: Your Nitrous.IO account is delinquent.")
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

  describe "upgrade_failed_alert" do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription) { create :subscription, user: user, state: 'active' }
    let!(:attempted_plan) { create :plan }

    it "sends an email to the user informing that the upgrade failed" do
      mail = SubscriptionMailer.upgrade_failed_alert user, attempted_plan

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Your upgrade to '#{attempted_plan.name}' has failed")
    end

    it "includes user's current card and plan details" do
      mail = SubscriptionMailer.upgrade_failed_alert user, attempted_plan

      expect(mail).to have_body_text("#############{billing_profile.last_four}")
      expect(mail).to have_body_text("#{billing_profile.card_type}")
      expect(mail).to have_body_text("#{billing_profile.exp_month}/#{billing_profile.exp_year}")
      expect(mail).to have_body_text("#{subscription.plan.name}")
    end
  end

end
