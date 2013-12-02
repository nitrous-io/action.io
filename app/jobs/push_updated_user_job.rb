class PushUpdatedUserJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    channel = Pusher["private-user-#{user_id}"]
    channel.trigger 'aio:user_updated', user.serialize_as_hash(scope: user).to_json
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(new(user_id))
  end
end
