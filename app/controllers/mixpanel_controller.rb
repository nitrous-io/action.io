class MixpanelController < ApplicationController
  def confirmation
    MixpanelWebhookHandler.delay.handle!(params[:users], params[:event])
    render nothing: true, status: :ok
  end
end
