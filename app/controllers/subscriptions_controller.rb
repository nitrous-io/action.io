class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    plan = SubscriptionPlan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    billing_profile = current_user.build_billing_profile

    if billing_profile.subscribe stripe_token, plan
      render nothing: true, status: :created
    else
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity
    end
  end

  def update
    billing_profile = current_user.billing_profile

    stripe_token = params[:stripe_token]
    plan = SubscriptionPlan.find params[:plan_id]

    if billing_profile && billing_profile.update_subscription(stripe_token, plan)
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
