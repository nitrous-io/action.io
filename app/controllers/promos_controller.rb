class PromosController < ApplicationController
  before_filter :authenticate_user!

  def index
    unless current_user.active_plan.present?
      current_user.coupon_code = params[:code]
      current_user.save
    end

    redirect_to pricing_url
  end
end
