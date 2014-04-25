class BoxTransition < ActiveRecord::Base
  # the goal is to always populate triggered_by, so any instances of
  # transitions with unknown trigger should be hunted down
  TRIGGERED_BY = %w(unknown user admin system webhook)

  belongs_to :box
  belongs_to :user

  validates :box, :event, :from_state, :to_state, :triggered_by, presence: true
  validates :triggered_by, inclusion: TRIGGERED_BY

  validate :validate_user_populated_if_triggered_by_user

  after_create :maybe_emit_to_datadog

  def set_user(val)
    raise "Expected User, got #{val}" if !val.is_a?(User)
    self.triggered_by = 'user'
    self.user = val
  end

protected
  def validate_user_populated_if_triggered_by_user
    return if self.triggered_by != 'user' || self.user
    errors.add(:user, "must have user id since triggered_by is user")
  end

  # maybe_emit_to_datadog emits to datadog the full roundtrip duration of
  # transitions from Rails->Coach->Goboxer and back.
  def maybe_emit_to_datadog # after_create
    # BoxTransitions triggered by users generally come in pairs:
    # e.g. transitions with events (enqueue_restart, restart) form a pair
    # The difference in created_at of the two is the time for the webapp
    # to recognize a successful state change.

    corresponding_event, metric_slug = case self.event.to_s
    when 'enqueue_start'
      ['enqueue_provision', 'provision']
    when 'enqueue_clone_repo' # repository present when creating box
      ['enqueue_start', 'start']
    when /^enqueue_/ # all other enqueues are ignored
      [nil, nil]
    when 'complete_clone_repo'
      ['enqueue_clone_repo', 'clone']
    else
      ["enqueue_#{self.event}", self.event]
    end

    return if metric_slug.nil?
    prev_box_transition = self.box.box_transitions.where('id < ?', self.id).order('id DESC').first # can be nil
    if prev_box_transition.try(:event) != corresponding_event
      Rails.logger.warn("Mismatched events on box #{self.box}, transitions: #{prev_box_transition.try(:id)}, #{self.id}")
      return
    end

    duration = self.created_at - prev_box_transition.created_at
    options = {
      tags: [Rails.env, "region:#{self.box.region.name}"],
      host: self.box.host
    }
    options[:stack] = self.box.box_template.name if self.box.box_template
    DatadogEmitPointJob.submit_job("nitrous_io.box_#{metric_slug}.timing",
                                   duration, options)
  end
end
