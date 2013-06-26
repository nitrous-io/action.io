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

  desc "Cleanup orphaned users"
  task :clean_orphaned_users => :environment do
    User.clean_orphaned_users 5.days.ago
  end

  desc "Fill n2o for oauth actions"
  task :fill_n2o_for_oauth => :environment do
    authentications = Authentication.find :all
    authentications.each do |authentication|
      user = authentication.user
      provider = authentication.provider

      if user.fill_n2o_for_oauth_action!(provider)
        puts "Filled n2o to #{user.username} for connecting #{provider}."
      end
    end
  end

  desc "Send thank you note to all private beta users"
  task :send_private_beta_thanks => :environment do
    User.where(in_private_beta: true).find_each(batch_size: 1000) do |user|
      unless user.n2o_fills.where(kind: N2oFill::Kind::FAVOR, amount: 100).any?
        user.fill_n2o! 100, N2oFill::Kind::FAVOR
      end

      UserMailer.private_beta_thanks(user.id).deliver
      puts "Filled 100 N2O and sent private beta thanks to #{user.username}"
    end
  end
end
