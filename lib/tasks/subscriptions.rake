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
end
