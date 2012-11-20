# encoding: utf-8

module InvitesHelper
  def prettified_state_for(invite)
    case invite.state
    when 'activated' then 'sent'
    when 'accepted'  then '✓ accepted'
    else invite.state
    end
  end
end
