class UserProfile < ActiveRecord::Base
  belongs_to :user

  serialize :mixpanel_properties, JSON

  attr_accessible :subscribed_to_monthly_newsletter, :subscribed_to_product_announcements

  before_save :track_mailchimp_subscription_changes
  after_save  :update_mailchimp

  protected
  def track_mailchimp_subscription_changes
    return if new_record?

    @subscribed_to_monthly_newsletter_changed = self.subscribed_to_monthly_newsletter_changed?
    @subscribed_to_product_announcements_changed = self.subscribed_to_product_announcements_changed?

    nil # prevent falsy returns
  end

  def update_mailchimp
    if @subscribed_to_monthly_newsletter_changed
      event = subscribed_to_monthly_newsletter ? 'subscribe' : 'unsubscribe'
      MailchimpJob.submit_job(event, Settings.mailchimp_monthly_newsletter_list_id, user_id: user.id)
    end

    if @subscribed_to_product_announcements_changed
      event = subscribed_to_product_announcements ? 'subscribe' : 'unsubscribe'
      MailchimpJob.submit_job(event, Settings.mailchimp_product_announcements_list_id, user_id: user.id)
    end
  end
end
