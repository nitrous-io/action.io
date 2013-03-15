namespace :actionio do
  desc "Send admins information about dangling boxes"
  task :send_dangling_boxes_information => :environment do
    if Box.dangling.count > 0
      puts "Sending Dangling Boxes Information"
      Notifier.dangling_boxes_information.deliver
    end
  end

  desc "Create a delayed job to archive all idle boxes"
  task :archive_all_idle_boxes => :environment do
    puts "Archiving Idle Boxes"
    # give ample time to archive and not throttle a single box host
    # we should not have a very big number of idle boxes when we run this
    # frequenly though. Furthermore, we guarantee that there is only one
    # ArchiveIdleBoxesJob in the queue
    ArchiveIdleBoxesJob.submit ArchiveIdleBoxesJob.new(5, 20.minutes)
  end
end
