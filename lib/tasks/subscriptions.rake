namespace :actionio do
  desc "Send an alert to the users with credit cards expiring this month"
  task :send_credit_card_expiring_alert => :environment do
    # TODO: Modify this to run only on 1st, 15th and last day of the month
    expiring_profiles = BillingProfile.find_profiles_with_expiring_cards Date.today
    puts "#{expiring_profiles.count} profiles with expiring cards to be alerted"
    expiring_profiles.each do |profile|
      SubscriptionMailer.credit_card_expiring_alert(profile).deliver
    end
  end

  task :archive_canceled_subscriptions => :environment do
    class OldUser < ActiveRecord::Base
      set_table_name 'users'
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
end
