class MixpanelController < ApplicationController
  before_filter :authenticate_request!, only: [:confirmation]

  def confirmation
    MixpanelWebhookHandler.delay.handle!(params[:users], params[:event])
    render nothing: true, status: :ok
  end

  protected
  def authenticate_request!
    unless params[:key] == Settings.mixpanel_webhook_key
      render nothing: true, status: :forbidden
      return
    end
  end
end
