class Notifier < ActionMailer::Base
  layout 'email'
  helper 'email'
  default :from => 'Action.IO Team <hello@action.io>'

  def invite_confirmation(invite_id)
    @invite = Invite.find(invite_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration')
    mail(subject: "Welcome to Action.IO - Your Dev Environment in the Cloud",
         to:      @invite.email)
  end

end