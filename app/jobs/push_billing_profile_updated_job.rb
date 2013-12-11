class PushBillingProfileUpdatedJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(user_id)
    billing_profile = user.billing_profile
    payload = billing_profile.serialize_as_hash

    Shover.publish user_id, 'aio:billing_profile_updated', payload
    Pusher["private-user-#{user_id}"].trigger 'aio:billing_profile_updated', payload
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(new(user_id))
  end
end
