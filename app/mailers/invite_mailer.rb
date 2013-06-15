class InviteMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

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

  def send_collaboration_invite(invite_id)
    @invite       = CollaborationInvite.find(invite_id)
    @box          = @invite.box
    @user         = @box.owner
    @box_template = @box.box_template

    mail(subject: "Invitation to Try Nitrous.IO - Collaborate and Code with #{@user.username}",
         to:      @invite.email)
  end

end
