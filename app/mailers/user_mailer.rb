class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def welcome(email)
    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration-success')
    mail(subject: "Getting Started on Nitrous.IO",
         to:      email)
  end

  def n2o_bonus_alert(n2o_fill_id)
    @n2o_fill = N2oFill.find(n2o_fill_id)
    @user = @n2o_fill.user

    mail(subject: "Congrats! We allocated #{@n2o_fill.amount} units of N2O to your Nitrous.IO account",
         to: @user.email)
  end

  def private_beta_thanks(user_id)
    @user = User.find(user_id)

    mail(subject: "Nitrous.IO is now open to all! Thank you for participating in our private beta",
         to: @user.email)
  end
end
