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

      # Ignore Cersei boxes because the LXC config for CPU shares and swap
      # can't be changed on-the-fly.
      next if box.version == 'cersei'

      # Skip boxes that don't need to be reconfigured.
      next unless box.configuration_changed?

      # If box is currently reconfiguring, we'll wait for it to change to a
      # different state so that we don't risk an inconsistent box config.
      requeue(box_id) and next if box.reconfiguring?

      box.pending_reconfiguration = true
      if box.save
        box.soft_reconfigure
      end
    end
  end

  def requeue(box_id)
    job = self.class.new(box_ids: [box_id], cpu_multiplier: cpu_multiplier, vmem_multiplier: vmem_multiplier)
    Delayed::Job.enqueue(job, run_at: 1.minute.from_now)
  end

  def self.submit_job(box_ids: [], cpu_multiplier: 1, vmem_multiplier: 1)
    job = new(box_ids: box_ids, cpu_multiplier: cpu_multiplier, vmem_multiplier: vmem_multiplier)
    Delayed::Job.enqueue(job)
  end
end
