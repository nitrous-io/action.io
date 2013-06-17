class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def welcome(email)
    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration-success')
    mail(subject: "Getting Started on Nitrous.IO",
         to:      email)
  end
end
