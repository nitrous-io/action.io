class SubscriptionMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def subscription_activated(subscription_id)
    subscription = Subscription.find subscription_id
    @plan = subscription.plan
    @user = subscription.user

    mail(subject: "Your new #{@plan.name} subscription is active",
         to: @user.email,
         bcc: 'billing+success@nitrous.io')
  end

  def payment_failed_alert(subscription_id)
    @subscription = Subscription.find subscription_id
    @plan = @subscription.plan
    @user = @subscription.user
    @billing_profile = @user.billing_profile

    mail(subject: "Your subscription payment for '#{@plan.name}' has failed",
         to: @user.email)
  end

  def credit_card_changed_alert(billing_profile_id)
    @billing_profile = BillingProfile.find billing_profile_id
    @user = @billing_profile.user

    mail(subject: "Your credit card changed",
         to: @user.email)
  end

  def credit_card_expiring_alert(billing_profile)
    @billing_profile = billing_profile
    @user = @billing_profile.user

    mail(subject: "[Action required] Your credit card will expire this month",
         to: @user.email,
         bcc: "billing+expiries@nitrous.io")
  end
end
