require "csv"

namespace :actionio do
  desc "Identify Users on Mixpanel"
  task :identify_users_on_mixpanel => :environment do
    User.all.each do |user|
      IdentifyMixpanelUserJob.new(user.id).perform
      puts "Identified #{user.inspect}"
    end
  end

  desc "Export users list as a CSV"
  task :export_users_csv => :environment do
    output = CSV.generate do |csv|
      csv << ["username", "full_name", "email"]
      User.order(:username).find_in_batches do |group|
        group.each do |user|
          csv << [user.username, user.full_name, user.email]
        end
      end
    end

    puts output
  end

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

  desc "Remove all fake email providers"
  task :remove_all_fake_email_users => :environment do
    email_condition = EMAIL_BLACKLIST.map { |e| "email ILIKE '%#{e}'" }.join(' OR ')

    puts "********************************************"
    puts "NEED TO DESTROY BOXES FIRST FOR THESE USERS:"
    puts "********************************************"

    User.where(email_condition).select { |u| u.owned_boxes.count > 0 }.each do |u|
      puts u.email
    end

    puts "*****************************"
    puts "DESTROYING USERS WITHOUT BOXES"
    puts "*****************************"

    User.where(email_condition).select { |u| u.owned_boxes.count == 0 }.each do |u|
      u.destroy
    end

    puts "***********************************"
    puts "DESTROYING DUPE USERS WITHOUT BOXES"
    puts "***********************************"

    User.where("email ILIKE '%+%'").each do |u|
      email_addendum = (u.email.match(/\+(.*?)@/) || [])[1]
      if email_addendum
        stripped_email = u.email.gsub(/\+#{email_addendum}/, '')

        if User.find_by_email(stripped_email)
          if u.owned_boxes.count > 0
            puts "#{u.email}"
          else
            u.destroy
          end
        end
      end
    end
  end
end
