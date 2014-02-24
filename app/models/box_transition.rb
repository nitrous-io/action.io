class BoxTransition < ActiveRecord::Base
  # the goal is to always populate triggered_by, so any instances of
  # transitions with unknown trigger should be hunted down
  TRIGGERED_BY = %w(unknown user admin system)

  belongs_to :box
  belongs_to :user

  validates :box, :event, :from_state, :to_state, :triggered_by, presence: true
  validates :triggered_by, inclusion: TRIGGERED_BY

  validate :validate_user_populated_if_triggered_by_user

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
end
