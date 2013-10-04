class MigrateBoxesJob < JobBase
  unique true
  attr_accessor :num_box, :next_run, :region_id, :states

  def initialize(region_id, states, num_box, next_run)
    self.states = states
    self.region_id = region_id
    self.num_box = num_box
    self.next_run = next_run
  end

  def perform
    boxes = Box.where(version: %w(arya bran), region_id: region_id,
                      state: states).limit self.num_box
    return if boxes.blank?
    boxes.each { |box| box.start_migration }
    next_job = self.class.new(self.region_id, self.states, self.num_box, self.next_run)
    self.class.submit next_job, run_at: self.next_run.from_now
  end
end
