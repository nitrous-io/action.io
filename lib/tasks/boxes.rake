namespace :actionio do
  desc "Send admins information about dangling boxes"
  task :send_dangling_boxes_information => :environment do
    if Box.dangling.count > 0
      puts "Sending Dangling Boxes Information"
      Notifier.dangling_boxes_information.deliver
    end
  end

  desc "Create a delayed job to archive inactive boxes"
  task :archive_inactive_boxes => :environment do
    puts "Archiving Inactive Boxes"
    # give ample time to archive and not throttle a single box host
    # we should not have a very big number of idle boxes when we run this
    # frequenly though. Furthermore, we guarantee that there is only one
    # ArchiveInactiveBoxesJob in the queue
    ArchiveInactiveBoxesJob.submit ArchiveInactiveBoxesJob.new(5, 20.minutes)
  end

  desc "Create a delayed job to stop idle boxes"
  task :stop_idle_boxes => :environment do
    puts "Stopping Idle Boxes"
    StopIdleBoxesJob.submit StopIdleBoxesJob.new(5, 20.minutes)
  end
end
