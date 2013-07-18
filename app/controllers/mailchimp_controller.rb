class MailchimpController < ApplicationController
  before_filter :authenticate_request!, only: [:webhook]

  def webhook
    case type = params[:type]
    when 'unsubscribe'
      mark_as_unsubscribed params[:data][:email]
    end

    render nothing: true, status: :no_content
  end

  protected
  def mark_as_unsubscribed(email)
    if user = User.find_by_email(email)
      profile = user.user_profile || user.build_user_profile
      profile.should_update_mailchimp = false
      profile.update_attribute(:subscribed_to_newsletter, false)
    end
  end

  def authenticate_request!
    params[:key] == Settings.mailchimp_webhook_key
  end
end
