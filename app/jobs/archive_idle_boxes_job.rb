class ArchiveIdleBoxesJob < JobBase
  unique true
  attr_accessor :num_box, :next_run

  def initialize(num_box, next_run)
    self.num_box = num_box
    self.next_run = next_run
  end

  def perform
    boxes = Box.idle.limit self.num_box
    return if boxes.blank?
    boxes.each { |box| box.enqueue_archive! }
    next_job = ArchiveIdleBoxesJob.new(self.num_box, self.next_run)
    self.class.submit next_job, run_at: self.next_run.from_now
  end
end
