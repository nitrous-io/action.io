class DowngradeBoxesJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    boxes = Box.find_all_requiring_restart(user_id)
    boxes.select! { |box| box.requires_downgrade? }

    not_running_count = 0
    boxes.each do |box|
      if box.running?
        box.transition_triggered(:enqueue_restart!, 'system')
      else
        not_running_count += 1
      end
    end

    requeue(user_id) if not_running_count > 0
  end

  def requeue(user_ud)
    job = self.class.new(user_ud)
    Delayed::Job.enqueue(job, run_at: 5.minutes.from_now)
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(new(user_id))
  end
end
