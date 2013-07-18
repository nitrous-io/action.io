class UserProfile < ActiveRecord::Base
  belongs_to :user
  attr_accessible :subscribed_to_newsletter

  attr_accessor :subscribed_to_newsletter_modified, :should_update_mailchimp

  before_save :track_subscribed_to_newsletter_change
  after_save :update_mailchimp

  protected
  def track_subscribed_to_newsletter_change
    self.subscribed_to_newsletter_modified = self.subscribed_to_newsletter_changed?
    nil # prevent falsy returns
  end

  def update_mailchimp
   return unless self.should_update_mailchimp && self.subscribed_to_newsletter_modified

   if self.subscribed_to_newsletter
     MailchimpJob.submit_job "subscribe", user.email
   else
     MailchimpJob.submit_job "unsubscribe", user.email
   end
  end
end
