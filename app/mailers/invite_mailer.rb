class InviteMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Nitrous.IO Team <hello@nitrous.io>'

  def send_confirmation(invite_id)
    @invite = Invite.find(invite_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration')
    mail(subject: "Welcome to Nitrous.IO - Your Dev Environment in the Cloud",
         to:      @invite.email)
  end

  def send_invite(invite_id)
    @invite = Invite.find(invite_id)
    @user = User.find_by_email(@invite.email)

    mail(subject: "Welcome to Nitrous.IO",
         to:      @invite.email)
  end
end
