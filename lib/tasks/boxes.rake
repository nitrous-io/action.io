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
    Delayed::Job.enqueue ArchiveIdleBoxesJob.new(20, 1.minutes)
  end
end
