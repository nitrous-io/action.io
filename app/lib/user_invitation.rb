class UserInvitation < Struct.new(:user)
  NO_INVITE_LEFT = Class.new

  # Create an invitation to specified email. If the email has never requested
  # for invitation before, we will create a new invitation belongs to current
  # user.
  #
  # email - String of email address that we want to invite
  #
  # Returns NO_INVITE_LEFT when the user reached max_invite, or an instance of
  # `Invite` model which can be invalid/valid. So remember to check the
  # validity of `invite` when processing result later
  def invite(email)
    return NO_INVITE_LEFT unless user.able_to_invite?

    invite = user.owned_invite_with_email(email)
    if invite.present?
      InviteMailer.delay.send_invite(invite.id)
    else
      invite = new_invite(email)
      InviteMailer.delay.send_invite(invite.id) if invite.activated?
    end
    invite
  end

  # Save a new activated invitation belongs to this user
  #
  # email - String of email address that we want to create an invitation for
  #
  # Returns an instance of `Invite`
  def new_invite(email)
    Invite.new.tap do |invite|
      invite.email = email
      invite.inviting_user = self.user
      invite.save
      invite.activate! if invite.persisted?
    end
  end
end
