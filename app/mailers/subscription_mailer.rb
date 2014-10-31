class SubscriptionMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  helper 'receipt'
  default from: "Nitrous <support@#{ENV['RAILS_DOMAIN']}>"

  def subscription_activated(subscription_id)
    subscription = Subscription.find subscription_id
    @plan = subscription.plan
    @user = subscription.user

    mail(subject: "Your new #{@plan.name} subscription is active",
         to: @user.email,
         bcc: 'billing+success@nitrous.io')
  end

  def subscription_canceled(subscription_id)
    subscription = Subscription.find subscription_id
    @plan = subscription.plan
    @user = subscription.user

    mail(subject: "Your #{@plan.name} subscription has been canceled",
         to: @user.email,
         bcc: 'billing@nitrous.io')
  end

  def payment_failed_alert(subscription_id, params={})
    missing_params = %i(attempt_count amount_due billing_period) - params.keys
    raise "Missing params: #{missing_params}" if !missing_params.empty?

    @subscription = Subscription.find subscription_id
    @plan = @subscription.plan
    @user = @subscription.user
    @billing_profile = @user.billing_profile

    @attempt_count = params[:attempt_count]
    @amount_due = params[:amount_due]
    @billing_period = params[:billing_period]

    @final_notice = false

    case @attempt_count
    when 0, 1
      @subject = "Your subscription payment for '#{@plan.name}' has failed"
    when (2..Subscription::MAX_CHARGE_ATTEMPTS-2)
      @subject = "#{@attempt_count.ordinalize} Notice: Your subscription payment for '#{@plan.name}' has failed"
    when Subscription::MAX_CHARGE_ATTEMPTS - 1
      @subject = "Final Notice: Your subscription payment for '#{@plan.name}' has failed"
      @final_notice = true
    else
      raise "Unexpected fallthrough, attempt_count #{@attempt_count}"
    end

    mail(subject: @subject, to: @user.email)
  end

  def delinquency_alert(subscription_id)
    @subscription = Subscription.find subscription_id
    @user = @subscription.user

    @subject = "Delinquency Notice: Your Nitrous account is delinquent."

    mail(subject: @subject, to: @user.email)
  end

  def credit_card_changed_alert(user_id)
    @user = User.find user_id
    @billing_profile = @user.billing_profile

    mail(subject: "Your credit card changed",
         to: @user.email)
  end

  def credit_card_expiring_alert(billing_profile)
    @billing_profile = billing_profile
    @user = @billing_profile.user

    mail(subject: "[Action required]: Your credit card will be expiring soon",
         to: @user.email,
         bcc: "billing+expiries@nitrous.io")
  end

  def upgrade_failed_alert(user, attempted_plan)
    @user = user
    @billing_profile = @user.billing_profile
    @current_plan = @user.subscription.plan

    @attempted_plan = attempted_plan

    mail(subject: "Your upgrade to '#{@attempted_plan.name}' has failed",
         to: @user.email)
  end

  def subscription_trial_expiring_alert(user_id)
    @user = User.find user_id

    mail(subject: "Your Nitrous Free Trial is about to expire",
         to: @user.email,
         bcc: "billing+trial_expiries@nitrous.io")
  end
end
