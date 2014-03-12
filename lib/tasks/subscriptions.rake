namespace :actionio do
  desc "Send an alert to the users with credit cards expiring this month"
  task :send_credit_card_expiring_alert => :environment do
    expiring_profiles = BillingProfile.needs_expiration_alert(1.month.from_now)
    expiring_profiles.each do |profile|
      SubscriptionMailer.credit_card_expiring_alert(profile).deliver
      profile.update_attribute :expiration_notice_sent_at, Time.now
    end
  end

  task :archive_canceled_subscriptions => :environment do
    class OldUser < ActiveRecord::Base
      self.table_name = 'users'
      has_many :subscriptions, foreign_key: 'user_id'
    end

    OldUser.all.each do |user|
      subscriptions = user.subscriptions
      next if subscriptions.blank? || subscriptions.count <= 1

      puts "User '#{user.username}' (ID: #{user.id}) has #{subscriptions.count} subscriptions"
      subscriptions.each do |sub|
        puts "  Subscription: <id: #{sub.id}, state: #{sub.state}, created_at: #{sub.created_at}, updated_at: #{sub.updated_at}>"
      end

      # Copy all canceled subscriptions to PastSubscription
      subscriptions.where(state: 'canceled').each do |sub|
        PastSubscription.archive(sub)
        sub.delete
      end

      puts "  ----- after cleanup -----"
      subscriptions = user.reload.subscriptions
      subscriptions.each do |sub|
        puts "  Subscription: <id: #{sub.id}, state: #{sub.state}, created_at: #{sub.created_at}, updated_at: #{sub.updated_at}>"
      end
    end
  end

  desc "I'm sorry. We only need this once to fixup bad data on staging."
  task :cleanup_fucked_up_payment_models_on_staging => :environment do
    puts "Deleting subscriptions with no user_id"
    Subscription.where(user_id: nil).each do |sub|
      puts "  deleting: #{sub.inspect}"
      sub.delete
    end
    puts "Deleting billing profiles with no user_id"
    BillingProfile.where(user_id: nil).each do |bp|
      puts "  deleting: #{bp.inspect}"
      bp.delete
    end
  end
end
