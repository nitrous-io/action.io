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
      csv << ["id", "email", "registered", "subscribed", "canceled"]
      Subscription.includes(:user).canceled.find_in_batches do |group|
        group.each do |subscription|
          user = subscription.user
          created_at = user.created_at.strftime('%e %b %Y %H:%m:%S%p')
          subscribed_at = subscription.created_at.strftime('%e %b %Y %H:%m:%S%p')
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

  desc "Set banned mixpanel property on already banned users"
  task :set_banned_in_mixpanel => :environment do
    User.banned.find_each do |banned_user|
      SetMixpanelPropertyJob.submit_job banned_user.id, :banned, true
      puts "Added banned property to #{banned_user.username}"
    end
  end

  # one-off task for updating: min RAM -> 512, min disk -> 1500, initial n20 -> 200
  task :meteor_bumps => :environment do
    ActiveRecord::Base.transaction do
      {
        n2o_min_memory_mb: 512,
        n2o_min_storage_mb: 1500,
        n2o_signup_bonus: 200,
      }.each do |k, v|
        kv = KeyValue.find_by_key(k)
        kv.value = v
        kv.save!
      end
      N2oFill.where(kind: N2oFill::Kind::SIGN_UP).update_all(amount: 200)
      # only necessary part of User#update_balance! for speedier update
      # * Skipping PushCurrentN2oBalanceJob = users won't get immediate notification
      # * Skipping SetMixpanelPropertyJob = mixpanel free_n2o property will be
      # out of date, can be rectified outside of this task
      ActiveRecord::Base::connection.execute <<-SQL
        UPDATE users SET max_n2o =
          (SELECT COALESCE(SUM(n2o_fills.amount), 0) FROM n2o_fills WHERE n2o_fills.user_id = users.id)
      SQL
    end
  end

  # one-off task for backfilling {,un}subscribed_at in mixpanel
  # have to run explicitly with DRY_RUN=FALSE in order to actually send to
  # mixpanel, otherwise results are output to stdout
  task :backfill_subscribed_at => :environment do
    # find_each is order 'id ASC', so the most recent {,un}subscription of a
    # user will be the one ultimately tracked
    dry_run = ENV['DRY_RUN'] != 'FALSE'
    puts "Dry run is #{dry_run}"
    Subscription.where('state != ?', 'pending').find_each do |sub|
      props = {:subscribed_at => sub.created_at}

      # updated_at not guaranteed to be unsubscribed_at, but best we can do
      props[:unsubscribed_at] = sub.updated_at if sub.state == 'canceled'
      args = [sub.user_id, props]
      if dry_run
        puts "Will call mixpanel with #{args}"
      else
        SetMixpanelPropertyJob.submit_job(*args)
      end
    end
  end

  task :send_paid_reminders => :environment do
    # parse csv from Pro database
    CSV.foreach(ENV['CSV_PATH']) do |row|
      email, lite_username, pro_username, reset_password_token = row
      matches = User.where(:email => email, :username => lite_username)
      if matches.size != 1
        puts "Multiple matches for email #{email}"
        next
      end
      SendFinalReminderPaidJob.submit_job(matches[0].id, pro_username, reset_password_token)
    end
  end
end
