class PapertrailController < ApplicationController
  before_filter :authenticate_request!, only: [:webhook]

  def webhook
    PapertrailEventParser.delay.parse!(params[:payload])
    render nothing: true, status: :ok
  end

  protected
  def authenticate_request!
    unless params[:key] == Settings.papertrail_webhook_key
      render nothing: true, status: :forbidden
      return
    end
  end
end
