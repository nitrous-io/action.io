class WufooController < ApplicationController
  protect_from_forgery except: [:webhook]
  before_filter :authenticate_request!, only: [:webhook]

  def webhook
    case params[:form_id]
    when 'nitrous-for-business'
      user = User.find_by_username(params[:Field9])
      user ||= User.find_by_email(params[:Field11])

      user.fill_n2o_for_business_survey! if user
    end

    render nothing: true, status: :ok
  end

  protected
  def authenticate_request!
    unless params[:HandshakeKey] == Settings.wufoo_webhook_key
      render nothing: true, status: :forbidden
      return
    end
  end
end
