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
    Box.idle(1.day.ago).each { |b| b.enqueue_stop! }
  end

  desc "Migrate all boxes to lvm"
  task :migrate_to_lvm, [:region_id] => [:environment] do |t, args|
    region_id = args[:region_id].to_i
    puts "Migrating to lvm for region_id: #{region_id}"
    MigrateBoxesJob.submit MigrateBoxesJob.new(region_id, 3, 5.minutes)
  end

  desc "Change the host domain of all boxes"
  task :change_host, [:old_domain], [:new_domain] => [:environment] do |t, args|
    old_domain = args[:old_domain] || "actionbox.io"
    new_domain = args[:new_domain] || "nitrousbox.com"

    puts "Changing the host of all boxes from #{old_domain} to #{new_domain}"
    Box.find_each(batch_size: 1000) do |box|
      if host = box.host
        box.host = host.gsub old_domain, new_domain
        box.save
      end
    end
  end

end
