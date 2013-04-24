class JobBase
  class << self
    attr_accessor :is_unique
    def unique(val); self.is_unique = val; end

    def submit(job, options = {})
      return nil if self.is_unique && job.enqueued?
      Delayed::Job.enqueue job, options
    end

    def find_jobs(job)
      Delayed::Job.where(:handler => job.to_yaml)
    end
  end

  def enqueued?
    !self.class.find_jobs(self).
      where(Delayed::Job.arel_table[:locked_at].eq(nil)).
      empty?
  end
end
