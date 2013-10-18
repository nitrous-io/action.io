class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    @plan = SubscriptionPlan.find(params[:plan_id])
    coupon = Coupon.active.find_by_code(params[:coupon_code])
    stripe_token = params[:stripe_token]

    @billing_profile = current_user.build_billing_profile(plan: @plan, stripe_token: stripe_token)
    @billing_profile.coupon = coupon

    if @billing_profile.save
      render nothing: true, status: :created
    else
      render json: @billing_profile.errors, status: :unprocessable_entity
    end
  end

  def update
    @billing_profile = current_user.billing_profile

    @billing_profile.stripe_token = params[:stripe_token]

    unless params[:plan_id].blank?
      @billing_profile.plan = SubscriptionPlan.find(params[:plan_id].to_i)
    end

    unless params[:coupon_code].blank?
      @billing_profile.coupon = Coupon.active.find_by_code(params[:coupon_code])
    end

    if @billing_profile.save
      render nothing: true, status: :ok
    else
      render json: @billing_profile.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @billing_profile = current_user.billing_profile

    if @billing_profile.cancel_subscription
      render nothing: true, status: :ok
    else
      render json: @billing_profile.errors, status: :unprocessable_entity
    end
  end
end
