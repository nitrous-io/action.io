class Notifier < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Nitrous.IO Team <hello@nitrous.io>'

  def dangling_boxes_information
    created_at = 10.minutes.ago

    @dangling_boxes = Box.dangling.where("created_at < ?", created_at).order("created_at DESC")


    headers["X-SMTPAPI"] = JSON.generate(category: 'nitrous-admin')

    mail(subject: "Dangling Boxes on #{ENV['RAILS_HOST']} as of #{created_at.strftime('%e %b %Y %H:%m:%S%p')}",
         to:      "eng@nitrous.io")
  end

  def box_provisioning_failed(box_id)
    @box = Box.find(box_id)

    headers["X-SMTPAPI"] = JSON.generate(category: 'nitrous-admin')

    mail(subject: "Provisioning Failed - Box #{@box.id}",
         to:      "eng@nitrous.io")
  end

  def collaboration_invite(route={})
    @from_user = User.find(route[:from])
    @to_user = User.find(route[:to])
    @box = Box.find(route[:box])

    headers["X-SMTPAPI"] = JSON.generate(category: 'collaboration-invite')
    mail(subject: "Invitation to collaborate on #{@box.name} on Nitrous.IO",
         to:      @to_user.email)
  end

  def collaboration_notification(user_id, author, box_name)
    @to_user = User.find(user_id)
    @author = author
    @box_name = box_name

    headers["X-SMTPAPI"] = JSON.generate(category: 'notify-collaborator')
    mail(subject: "#{@author} mentioned you in the box \"#{@box_name}\"",
         to:      @to_user.email)
  end
end
