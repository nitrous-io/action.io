class SendTerminationNoticeJob < Job
  attr_accessor :box_id

  def initialize(box_id)
    self.box_id = box_id
  end

  def perform
    # no-op, with sunset looming these do not need to go out

    # box = Box.find(box_id)
    # box.update_attribute :termination_notice_sent_at, Time.now

    # UserMailer.box_termination_notice(box_id).deliver
    # TrackMixpanelEventJob.submit_job('Box Termination Notice Sent', box.owner.id, box_id: box_id, touched_at: box.touched_at)
  end

  def self.submit_job(box_id)
    Delayed::Job.enqueue(new(box_id))
  end
end
