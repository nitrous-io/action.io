namespace :actionio do
  desc "Mark all invites associated with users to be accepted"
  task :mark_invites_as_accepted => :environment do
    User.all.each do |user|
      if (invite = Invite.find_by_email(user.email)).present?
        invite.accept!
        invite.reload
        puts "Marked invite for #{invite.email} as #{invite.state}"
      end
    end
  end

  desc "Identify Users on Mixpanel"
  task :identify_users_on_mixpanel => :environment do
    User.all.each do |user|
      IdentifyMixpanelUserJob.new(user.id).perform
      puts "Identified #{user.inspect}"
    end
  end
end
