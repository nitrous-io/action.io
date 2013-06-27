class PushCurrentN2oBalanceJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(self.user_id)

    Pusher["private-user-#{self.user_id}"].trigger 'aio:n2o_updated',
                                                    {
                                                      n2o: {
                                                        max: user.max_n2o,
                                                        used: user.used_n2o
                                                      }
                                                    }
  end

  def self.submit_job(user)
    Delayed::Job.enqueue self.new(user.id)
  end
end
