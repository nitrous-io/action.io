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
    Box.idle(1.week.ago).each { |b| b.enqueue_stop! }
  end
end
