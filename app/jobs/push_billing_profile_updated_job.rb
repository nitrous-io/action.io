class PushBillingProfileUpdatedJob < Job
  attr_accessor :billing_profile_id

  def initialize(billing_profile_id)
    self.billing_profile_id = billing_profile_id
  end

  def perform
    billing_profile = BillingProfile.find(billing_profile_id)
    user_id = billing_profile.user_id
    payload = billing_profile.serialize_as_hash

    Shover.publish user_id, 'aio:billing_profile_updated', payload
    Pusher["private-user-#{user_id}"].trigger 'aio:billing_profile_updated', payload
  end

  def self.submit_job(billing_profile_id)
    Delayed::Job.enqueue(new(billing_profile_id))
  end
end
