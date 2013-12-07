class PushSubscriptionUpdatedJob < Job
  attr_accessor :subscription_id

  def initialize(subscription_id)
    self.subscription_id = subscription_id
  end

  def perform
    subscription = Subscription.find(subscription_id)
    user_id = subscription.user_id
    payload = subscription.serialize_as_hash

    Shover.publish user_id, 'aio:subscription_updated', payload
    Pusher["private-user-#{user_id}"].trigger 'aio:subscription_updated', payload
  end

  def self.submit_job(subscription_id)
    Delayed::Job.enqueue(new(subscription_id))
  end
end
