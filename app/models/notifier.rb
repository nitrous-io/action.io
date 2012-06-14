class Notifier < ActionMailer::Base
  layout 'email'
  helper 'email'
  default :from => 'Action.IO Team <hello@action.io>'

  def invite_confirmation(user_id)
    @user = User.find(user_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration')
    mail(subject: "Welcome to Action.IO - Your Dev Environment in the Cloud",
         to:      @user.email)
  end

end