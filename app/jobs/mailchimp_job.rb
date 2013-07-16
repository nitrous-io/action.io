class MailchimpJob < Job
  attr_accessor :event, :user_id

  def initialize(event, user_id = nil, properties={})
    self.event = event
    self.user_id = user_id
  end

  def perform
    if self.user_id.present?
      user = User.find(self.user_id)
    end

    if self.event == "subscribe"
      Gibbon.listSubscribe({ id: Settings.mailchimp_list_id,
                             email_address: user.email,
                             merge_vars: { EMAIL: user.email },
                             double_optin: false,
                             update_existing: true
                           })
    end
  end

  def self.submit_job(event, user_id = nil)
    Delayed::Job.enqueue(self.new(event, user_id))
  end
end


