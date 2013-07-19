class MailchimpController < ApplicationController
  before_filter :authenticate_request!, only: [:webhook]

  def webhook
    case params[:type]
    when 'unsubscribe'
      data = params[:data]
      mark_as_unsubscribed data[:email], data[:list_id]
    end

    render nothing: true, status: :ok
  end

  protected
  def mark_as_unsubscribed(email, list_id)
    if user = User.find_by_email(email)
      profile = user.user_profile
      case list_id
      when Settings.mailchimp_monthly_newsletter_list_id
        profile.update_attribute(:subscribed_to_monthly_newsletter, false)
      when Settings.mailchimp_product_announcements_list_id
        profile.update_attribute(:subscribed_to_product_announcements, false)
      end
    end
  end

  def authenticate_request!
    unless params[:key] == Settings.mailchimp_webhook_key
      render nothing: true, status: :forbidden
      return
    end
  end
end
