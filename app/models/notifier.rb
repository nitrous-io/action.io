class Notifier < ActionMailer::Base
  layout 'email'
  helper 'email'
  default :from => 'Action.IO Team <hello@action.io>'

  def send_invite(invite_id)
    @invite = Invite.find(invite_id)

    mail(subject: "Welcome to Action.IO",
         to:      @invite.email)
  end

  def invite_confirmation(invite_id)
    @invite = Invite.find(invite_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration')
    mail(subject: "Welcome to Action.IO - Your Dev Environment in the Cloud",
         to:      @invite.email)
  end

  def invite_reminder(invite)
    @invite = invite
    @expiration_date = 14.days.from_now.to_formatted_s(:short_ordinal)

    headers["X-SMTPAPI"] = JSON.generate(category: 'user-registration')
    mail(subject: "Your Action.IO invite expires on #{@expiration_date}",
         to:      @invite.email,
         from:    "AJ Solimine <ajs@action.io>")
  end

  def dangling_boxes_information
    created_at = 10.minutes.ago

    @dangling_boxes = Box.dangling.where("created_at < ?", created_at).order("created_at DESC")


    headers["X-SMTPAPI"] = JSON.generate(category: 'actionio-admin')

    mail(subject: "Dangling Boxes on #{ENV['RAILS_HOST']} as of #{created_at.strftime('%e %b %Y %H:%m:%S%p')}",
         to:      "eng@action.io")
  end

  def box_provisioning_failed(box_id)
    @box = Box.find(box_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'actionio-admin')

    mail(subject: "Provisioning Failed - Box #{@box.id}",
         to:      "eng@action.io")
  end

  def collaboration_invite(route={})
    @from_user = User.find(route[:from])
    @to_user = User.find(route[:to])
    @box = Box.find(route[:box])

    headers["X-SMTPAPI"] = JSON.generate(category: 'collaboration-invite')
    mail(subject: "Invitation to collaborate on #{@box.name} on Action.IO",
         to:      @to_user.email)
  end
end
