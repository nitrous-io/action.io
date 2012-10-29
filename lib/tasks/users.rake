namespace :actionio do
  desc "Mark all invites associated with users to be accepted"
  task :mark_invites_as_accepted => :environment do
    User.all.each do |user|
      if (invite = Invite.find_by_email(user)).present?
        invite.accept!
        invite.reload
        puts "Marked invite for #{invite.email} as #{invite.state}"
      end
    end
  end
end
