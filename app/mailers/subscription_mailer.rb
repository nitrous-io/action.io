class SubscriptionMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def payment_failed_alert(subscription_id)
    @subscription = Subscription.find subscription_id
    @billing_profile = @subscription.billing_profile
    @plan = @subscription.subscription_plan
    @user = @billing_profile.user

    mail(subject: "Your subscription payment for '#{@plan.name}' has failed",
         to: @user.email)
  end

end
