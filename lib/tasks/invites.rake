namespace :actionio do
  desc "Set activated_at for all accepted invites"
  task :set_activated_at_accepted_at => :environment do
    invites = Invite.where("state = ? OR state = ?", 'activated', 'accepted')
    puts "set activated_at / accepted_at for all accepted invites: #{invites.count}"

    invites.each do |i|
      # Assume that i.updated_at is when the invite was set to accepted
      updated_at = i.updated_at
      attr = i.activated? ? :activated_at : :accepted_at
      i.update_attribute attr, updated_at
      p i
    end
  end

  desc "Send reminder to users who haven't accepted the invites"
  task :send_invite_reminder => :environment do
    puts "Sending reminder to invites older than 2 weeks"
    Invite.needs_reminder.each { |i| i.send_reminder!; p i }
  end

  desc "Send invites to all pending users"
  task :activate_pending_invites => :environment do
    puts "Activating all pending invites"
    Invite.where(state: "pending").each do |invite|
      invite.update_attribute :state, 'activated'
      InviteMailer.delay.send_tmp_invite invite.id
      TrackMixpanelEventJob.submit_job 'Invite Sent', nil, email: invite.email
    end
  end
end
