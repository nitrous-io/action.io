class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def n2o_bonus_alert(n2o_fill_id)
    @n2o_fill = N2oFill.find(n2o_fill_id)
    @user = @n2o_fill.user

    mail(subject: "Congrats! We allocated #{@n2o_fill.amount} units of N2O to your Nitrous.IO account",
         to: @user.email)
  end

  def n2o_purchased_alert(n2o_fill_id)
    @n2o_fill = N2oFill.find(n2o_fill_id)
    @user = @n2o_fill.user
    @subscription = @n2o_fill.resource
    @plan = @subscription.subscription_plan

    mail(subject: "Congrats! You purchased #{@n2o_fill.amount} units of N2O to your Nitrous.IO account",
         to: @user.email,
         bcc: 'billing+success@nitrous.io'
        )
  end

  def private_beta_thanks(user_id)
    @user = User.find(user_id)

    mail(subject: "Nitrous.IO is now open to all! Thank you for participating in our private beta",
         to: @user.email)
  end

  def box_memory_hit_limit_alert(box_id)
    @box = Box.find(box_id)
    @owner = @box.owner

    mail(subject: "You seem to have hit memory limits on your Nitrous.IO box - #{@box.name}",
         to: @owner.email)
  end

  def confirmation_reminder_1(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous.IO Account",
        to: @user.email,
        from: 'AJ Solimine <ajs@nitrous.io>')
  end

  def confirmation_reminder_2(user_id)
    @user = User.find(user_id)

    mail(subject: "Activate Your Nitrous.IO Account",
        to: @user.email,
        from: 'Greg <support@nitrous.io>')
  end

  def confirmation_reminder_3(user_id)
    @user = User.find(user_id)

    mail(subject: "Your Nitrous.IO Account is waiting",
        to: @user.email,
        from: 'Nitrous.IO <hello@nitrous.io>')
  end
end
