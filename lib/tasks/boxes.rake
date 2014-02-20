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

  desc "Send Box State Metrics to Datadog"
  task :send_metrics_to_datadog => :environment do
    Box::DANGLING_BOX_STATES.each do |state|
      global_count = 0
      counts = Box.count_by_group('region_name', state: state)
      counts['count'].each do |region, count|
        event = "#{region}.nitrous_io.#{Rails.env}.box_state.#{state}.count"
        Datadog.emit(event, count)
        global_counts += count
      end
      event = "global.nitrous_io.#{Rails.env}.box_state.#{state}.count"
      Datadog.emit(event, count)
    end
  end

  desc "Terminate boxes eligible for termination. Supports host, batch_size and delay args."
  task :terminate_eligible_boxes => :environment do
    batch_size = ENV['batch_size'] ? ENV['batch_size'].to_i : 100
    delay = ENV['delay'] ? ENV['delay'].to_i : 5
    host = ENV['host']
    if host.blank?
      puts "Please specify a host, e.g. host=apse1.nitrousbox.com."
      exit 1
    end

    puts "Terminating boxes..."
    Box.eligible_for_termination.where(host: host).find_in_batches(batch_size: batch_size) do |group|
      while (count = Box.where(host: host, state: 'terminating').count) >= 10
        puts "  waiting - there are #{count} terminating boxes"
        sleep 5
      end

      group.each do |box|
        "  box #{box.id}"
        box.enqueue_terminate
      end
      sleep delay
    end
    puts "Done."
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

  desc "Send apology email ʕ•ᴥ•ʔ to users whose boxes were incorrectly sent termination notices."
  task :send_termination_apology => :environment do
    puts "Sending apologies ʕ•ᴥ•ʔ..."

    Box.unterminated.
      where('termination_notice_sent_at IS NOT NULL').
      where(touched_at: nil). # untouched
      where('created_at >= ?', 3.months.ago). # created later than 3 months ago
      order(:id).
      find_each(batch_size: 100) do |b|
      UserMailer.box_termination_apology(b.id).deliver
      puts "  Emailed user #{b.owner_id}, box #{b.id}"
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

  desc "Create Boxes for User"
  task :create_boxes_for_user, [:username, :box_names, :box_template_name, :region_name, :memory, :storage, :collaborator_list] => [:environment] do |t, args|
    username = args[:username]
    box_names = args[:box_names].split(' ')
    region_name = args[:region]
    box_template_name = args[:box_template_name]
    memory = args[:memory]
    storage = args[:storage]
    collaborator_list = args[:collaborator_list].split(' ')

    user = User.find_by_username(username)
    raise ArgumentError, "User not found: #{username}" if user.nil?

    region_name = args[:region_name]
    if region_name.nil? || (region = Region.find_by_name(region_name)).nil?
      raise ArgumentError, "Region not found: #{region_name}"
    end

    box_template_name = args[:box_template_name]
    if box_template_name.nil? || (box_template = BoxTemplate.find_by_runtime(box_template_name)).nil?
      raise ArgumentError, "Box Template not found: #{box_template_name}"
    end

    memory = args[:memory] || KeyValue[Box::N2O_MIN_MEMORY_MB]
    storage = args[:storage] || KeyValue[Box::N2O_MIN_STORAGE_MB]

    box_names.each do |name|
      box = Box.new(
        name:    name,
        memory:  memory,
        storage: storage
      )
      box.box_template = box_template
      box.region = region
      box.owner = user

      puts "Creating Box: #{box.name} Memory: #{box.memory}M Storage: #{box.storage}M Region: #{region.name} Box Template: #{box_template.runtime}"

      if box.save
        box.enqueue_provision!
        IncrementMixpanelPropertyJob.submit_job(user.id, :boxes_created, 1)
        TrackMixpanelEventJob.submit_job('Box Created', user.id, { memory: box.memory, storage: box.storage, template: box.box_template.name, region: box.region.name })

        collaborator_list.each do |collab_username|
          box.add_collaborator(collab_username)
        end

        sleep 1
      end
    end
  end

end
