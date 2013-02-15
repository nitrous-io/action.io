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

  def dangling_boxes_information
    created_at = 10.minutes.ago

    @dangling_boxes = Box.dangling.where("created_at < ?", created_at).order("created_at DESC")


    headers["X-SMTPAPI"] = JSON.generate(category: 'actionio-admin')

    mail(subject: "Dangling Boxes on #{ENV['RAILS_HOST']} as of #{created_at.strftime('%e %b %Y %H:%m:%S%p')}",
         to:      "eng@action.io")
  end
end
