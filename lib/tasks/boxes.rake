namespace :actionio do
  desc "Send admins information about dangling boxes"
  task :send_dangling_boxes_information => :environment do
    if Box.dangling.count > 0
      puts "Sending Dangling Boxes Information"
      Notifier.dangling_boxes_information.deliver
    end
  end

  desc "Create a delayed job to stop idle boxes"
  task :stop_idle_boxes => :environment do
    puts "Stopping Idle Boxes"
    Box.free_idle.find_each(batch_size: 100) { |b| b.enqueue_stop! }
  end

  desc "Migrate all boxes to lvm"
  task :migrate_to_lvm, [:region_id] => [:environment] do |t, args|
    region_id = args[:region_id].to_i
    puts "Migrating to lvm for region_id: #{region_id}"
    MigrateBoxesJob.submit MigrateBoxesJob.new(region_id, 3, 5.minutes)
  end

  desc "Set premium flag on boxes of the paid users"
  task :set_premium_flag => [:environment] do |t, args|
    Subscription.where(state: 'active').each do |s|
      billing_profile = s.billing_profile
      user = billing_profile.user

      user.owned_boxes.each do |box|
        puts "setting premium flag on box #{box.id} owned by #{user.email}"
        box.update_premium
      end
    end
  end

end
