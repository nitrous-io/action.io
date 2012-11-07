class UserMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Action.IO Team <hello@action.io>'

  def welcome(email)
    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration-success')
    mail(subject: "Getting Started on Action.IO",
         to:      email)
  end
end
