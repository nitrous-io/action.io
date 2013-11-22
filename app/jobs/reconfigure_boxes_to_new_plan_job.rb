class ReconfigureBoxesToNewPlanJob < Job
  attr_accessor :box_ids, :cpu_multiplier, :vmem_multiplier

  def initialize(box_ids: [], cpu_multiplier: 1, vmem_multiplier: 1)
    self.box_ids = box_ids
    self.cpu_multiplier = cpu_multiplier
    self.vmem_multiplier = vmem_multiplier
  end

  def perform
    box_ids.each do |box_id|
      box = Box.find(box_id)
      box.virtual_memory = box.memory * vmem_multiplier
      box.cpu_multiplier = cpu_multiplier
      if box.configuration_changed? && box.save
        box.enqueue_reconfigure
      end

      # WARNING We might need to set a delay after each box (or batch of boxes)
      # so we don't overwhelm Boxer with too many reconfigures at once.
    end
  end

  def self.submit_job(box_ids: [], cpu_multiplier: 1, vmem_multiplier: 1)
    Delayed::Job.enqueue(new(box_ids: box_ids, cpu_multiplier: cpu_multiplier, vmem_multiplier: vmem_multiplier))
  end
end
