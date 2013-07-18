class MailchimpJob < Job
  attr_accessor :event, :email, :modified_email

  def initialize(event, email, modified_email)
    self.event = event
    self.email = email
    self.modified_email = modified_email
  end

  def perform
    case self.event
    when "subscribe"
      Gibbon.listSubscribe({ id: Settings.mailchimp_list_id,
                             email_address: self.email,
                             merge_vars: { EMAIL: self.modified_email },
                             double_optin: false,
                             update_existing: true
                           })
    when "unsubscribe"
      Gibbon.listUnsubscribe({ id: Settings.mailchimp_list_id,
                               email_address: self.email,
                               send_goodbye: false
                             })
    end
  end

  def self.submit_job(event, email = nil, modified_email = nil)
    Delayed::Job.enqueue(self.new(event, email, modified_email))
  end
end


