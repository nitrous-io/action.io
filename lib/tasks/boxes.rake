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
    Box.free_idle.find_each(batch_size: 100) do |b|
      b.force_shutdown_at = Time.now
      b.enqueue_stop!
    end
  end

  desc "Send box termination notices. Supports batch_size=X and delay=Y args."
  task :send_termination_notices => :environment do
    batch_size = ENV['batch_size'] ? ENV['batch_size'].to_i : 100
    delay = ENV['delay'] ? ENV['delay'].to_i : 5

    puts "Sending box termination notices - batch size: #{batch_size}, delay #{delay}s..."
    Box.due_for_termination_notice.find_in_batches(batch_size: batch_size) do |group|
      group.each do |b|
        puts "  Emailing user #{b.owner_id}, box #{b.id}"
        job = SendTerminationNoticeJob.new(b.id)
        # Run synchronously so we don't flood the job queue.
        job.perform
      end

      # Add a delay to let job queue clear up.
      sleep delay
    end
    puts "Done."
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
