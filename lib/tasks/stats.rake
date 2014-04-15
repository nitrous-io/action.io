namespace :actionio do
  desc "Mail Stats"
  task :mail_stats => :environment do
    puts "Sending Stats Mail"
    Notifier.stats.deliver
  end
end
