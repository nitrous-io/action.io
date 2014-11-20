class MailchimpJob < Job
  attr_accessor :event, :user_id, :email, :list_id

  def initialize(event, list_id, opts = {})
    self.event = event
    self.user_id = opts[:user_id]
    self.email = opts[:email]
    self.list_id = list_id
  end

  def perform
    email, unconfirmed_email, full_name = user_details

    return unless email

    case self.event
    when "subscribe"
      Gibbon.listSubscribe(id: self.list_id,
                           email_address: email,
                           merge_vars: {
                             EMAIL: unconfirmed_email,
                             FNAME: full_name
                           },
                           double_optin: false,
                           update_existing: true)
    when "unsubscribe"
      Gibbon.listUnsubscribe(id: self.list_id,
                             email_address: email,
                             send_goodbye: false)
    end

  rescue Gibbon::MailChimpError => e
    # common errors that we don't want to raise:
    # http://apidocs.mailchimp.com/api/1.3/exceptions.field.php
    # 215 - List_NotSubscribed
    # 220 - List_InvalidImport
    # 232 - Email_NotExists
    # 502 - Invalid_Email
    if [215, 220, 232, 502].include? e.code
      Rails.logger.warn e.message
    else
      raise e
    end
  end

  def self.submit_job(event, list_id, opts)
    Delayed::Job.enqueue(self.new(event, list_id, opts))
  end

  private
  def user_details
    email, unconfirmed_email, full_name = nil, nil, nil

    if self.user_id
      user = User.find(self.user_id)
      email = user.email
      unconfirmed_email = user.unconfirmed_email
      full_name = user.full_name || user.username
    elsif self.email
      email = self.email
    end

    return email, unconfirmed_email, full_name
  end
end
