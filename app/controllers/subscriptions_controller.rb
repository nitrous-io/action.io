class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    plan = Plan.find(params[:plan_id])
    coupon = Coupon.active.find_by_code(params[:coupon_code])
    stripe_token = params[:stripe_token]

    billing_profile = current_user.build_billing_profile
    billing_profile.coupon = coupon

    if billing_profile.subscribe stripe_token, plan
      render nothing: true, status: :created
    else
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity
    end
  end

  def update
    # FIXME: needs tests
    unless billing_profile = current_user.billing_profile
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity and return
    end

    stripe_token = params[:stripe_token]
    plan = params[:plan_id].present? && Plan.find(params[:plan_id])

    if billing_profile.update_subscription(stripe_token, plan)
      render nothing: true, status: :ok
    else
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    billing_profile = current_user.billing_profile

    if billing_profile.unsubscribe
      render nothing: true, status: :ok
    else
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity
    end
  end
end
