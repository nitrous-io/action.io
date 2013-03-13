class ArchiveIdleBoxesJob < Struct.new(:num_box, :next_run)
  def perform
    boxes = Box.idle.limit self.num_box
    return if boxes.blank?
    boxes.each { |box| box.enqueue_archive! }
    next_job = ArchiveIdleBoxesJob.new(self.num_box, self.next_run)
    Delayed::Job.enqueue next_job, run_at: self.next_run.from_now
  end
end
