class InviteMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous <support@#{ENV['RAILS_DOMAIN']}>"

  def send_invite(invite_id)
    @invite = Invite.find(invite_id)
    @user = User.find(@invite.inviting_user_id)

    mail(subject: "#{@user.username} invited you to Nitrous",
         to:      @invite.email)
  end

  def send_collaboration_invite(invite_id)
    @invite       = CollaborationInvite.find(invite_id)
    @box          = @invite.box
    @user         = @box.owner
    @box_template = @box.box_template
    @username     = @user.username.capitalize

    mail(subject: "#{@username} would like to code with you on Nitrous",
         to:      @invite.email)
  end

  def send_email_to_waiting_list_user(email)
    mail(subject: "Join the Nitrous Public Beta",
         to:      email)
  end

end
