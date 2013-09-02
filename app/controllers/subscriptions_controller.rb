class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    @plan = SubscriptionPlan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    @billing_profile = current_user.create_billing_profile(plan: @plan, stripe_token: stripe_token)

    if @billing_profile.persisted?
      render nothing: true, status: :created
    else
      render json: @billing_profile.errors, status: :unprocessable_entity
    end
  end

  def update
    @billing_profile = current_user.billing_profile

    if stripe_token = params[:stripe_token]
      @billing_profile.stripe_token = stripe_token
    elsif plan_id = params[:plan_id]
      @billing_profile.plan = SubscriptionPlan.find(plan_id)
    end

    if @billing_profile.save
      render nothing: true, status: :ok
    else
      render json: @billing_profile.errors, status: :unprocessable_entity
    end
  end
end
