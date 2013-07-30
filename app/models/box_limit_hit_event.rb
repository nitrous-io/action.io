class BoxLimitHitEvent < ActiveRecord::Base
  MEMORY          = "memory".freeze
  ALERT_FREQUENCY = 1.hour

  attr_accessible :box_id, :kind, :limit_hit_at, :logged_event_id

  validates_presence_of   :box_id, :kind, :limit_hit_at, :logged_event_id
  validates_uniqueness_of :logged_event_id

  belongs_to              :box

  after_create  :update_mixpanel, :update_box_last_hit_memory_limit_at

  protected
  def update_mixpanel
    box = self.box
    owner = box.owner

    TrackMixpanelEventJob.submit_job('Box Memory Limit Hit', owner.id,
                                     { memory: box.memory, storage: box.storage, template: box.box_template.name })
    IncrementMixpanelPropertyJob.submit_job(owner.id, :box_memory_limit_hit_count, 1)
  end

  def update_box_last_hit_memory_limit_at
    if self.kind == MEMORY
      box = self.box
      owner = box.owner
      now = Time.now

      if (box.last_hit_memory_limit_at.nil? || now - box.last_hit_memory_limit_at > ALERT_FREQUENCY) &&
         owner.admin?
        UserMailer.delay.box_memory_hit_limit_alert(box.id)
      end

      box.update_attribute(:last_hit_memory_limit_at, Time.now)
    end
  end
end
