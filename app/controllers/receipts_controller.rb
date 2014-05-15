class ReceiptsController < ApplicationController
  include ReceiptHelper # shared between receipts mailer, so the naming is singular
  before_filter :authenticate_user!
  respond_to :json

  def index
    @receipts = current_user.billing_profile.receipts.order_by_latest
    respond_with @receipts
  end

  def show
    @receipt = current_user.billing_profile.receipts.find params[:id]

    respond_to do |format|
      format.html { render :show, layout: false }
      format.json { render json: @receipt }
    end
  end
end
