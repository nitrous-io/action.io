class MailchimpJob < Job
  attr_accessor :event, :user_id, :list_id

  def initialize(event, user_id, list_id, opts = {})
    self.event = event
    self.user_id = user_id
    self.list_id = list_id
  end

  def perform
    user = User.find(self.user_id)

    case self.event
    when "subscribe"
      Gibbon.listSubscribe({ id: self.list_id,
                             email_address: user.email,
                             merge_vars: {
                               EMAIL: user.unconfirmed_email,
                               FNAME: user.full_name || user.username
                             },
                             double_optin: false,
                             update_existing: true
                           })
    when "unsubscribe"
      Gibbon.listUnsubscribe({ id: self.list_id,
                               email_address: user.email,
                               send_goodbye: false
                             })
    end
  end

  def self.submit_job(event, user_id, list_id)
    Delayed::Job.enqueue(self.new(event, user_id, list_id))
  end
end

