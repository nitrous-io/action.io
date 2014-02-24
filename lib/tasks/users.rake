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

  desc "Export canceled subscriptions to a CSV"
  task :export_canceled_subscriptions_csv => :environment do
    output = CSV.generate do |csv|
      csv << ["id", "email", "registered" "subscribed", "canceled"]
      Subscription.joins(:user).canceled.find_in_batches do |group|
        group.each do |subscription|
          user = subscription.user
          created_at = user.created_at.strftime('%e %b %Y %H:%m:%S%p')
          subscribed_at = subscription.created_at.strftime('%e %b %Y %H:%m:%S%p')

          # TODO: Track the cancelation time. Updated time might be inaccurate.
          canceled_at = subscription.updated_at.strftime('%e %b %Y %H:%m:%S%p')

          csv << [user.id, user.email, created_at, subscribed_at, canceled_at]
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

  desc "Create user profiles for all users"
  task :create_user_profiles => :environment do
    User.find_each(batch_size: 1000) do |user|
      user.user_profile
      puts "Created user profile for #{user.username}"
    end
  end

  desc "Augment Mixpanel Properties for Users"
  task :augment_mixpanel_properties => :environment do
    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']

    User.find_each(batch_size: 1000) do |user|
      bonus = user.bonus

      mixpanel.set user.email,
                   free_n2o: user.free_n2o,
                   chrome_app_installed: bonus.chrome_app.present?,
                   followed_on_twitter: bonus.twitter_follow.present?,
                   sent_tweet_on_twitter: bonus.tweet_sent.present?,
                   invited_friends: bonus.invite_friends.present?

      puts "Updated mixpanel properties for #{user.username}"
    end
  end

  desc "Add Twitter Info on Mixpanel"
  task :track_twitter_info_on_mixpanel => :environment do
    Authentication.joins(:user).where(provider: 'twitter').each do |auth|
      user = auth.user
      begin
        TrackTwitterInfoOnMixpanelJob.new(user.id).perform
      rescue
      end
      puts "Finished Twitter Tracking for User: #{user.username}"
    end
  end

  desc "Add Github Info on Mixpanel"
  task :track_github_info_on_mixpanel => :environment do
    Authentication.joins(:user).where(provider: 'github').each do |auth|
      user = auth.user
      begin
        TrackGithubInfoOnMixpanelJob.new(user.id).perform
      rescue
      end
      puts "Finished Github Tracking for User: #{user.username}"
    end
  end

  desc "Add Linkedin Info on Mixpanel"
  task :track_linkedin_info_on_mixpanel => :environment do
    Authentication.joins(:user).where(provider: 'linkedin').each do |auth|
      user = auth.user
      begin
        TrackLinkedinInfoOnMixpanelJob.new(user.id).perform
      rescue
      end
      puts "Finished Linkedin Tracking for User: #{user.username}"
    end
  end

  desc "Add Payment Details to Mixpanel for existing users"
  task :add_payment_details_to_mixpanel => :environment do
    Subscription.where(state: 'active').each do |s|
      billing_profile = s.billing_profile
      plan = s.plan
      user = billing_profile.user

      puts "setting mixpanel paid properties for #{user.email}"
      job = SetMixpanelPropertyJob.new user.id, paid_user: true, plan: plan.name
      job.perform
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
