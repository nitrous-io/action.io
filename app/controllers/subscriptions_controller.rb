class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    @plan = SubscriptionPlan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    @billing_profile = current_user.create_billing_profile(plan: @plan, stripe_token: stripe_token)
    render nothing: true, status: :accepted
  end

  def update
    @billing_profile = current_user.billing_profile

    if stripe_token = params[:stripe_token]
      @billing_profile.stripe_token = stripe_token
      @billing_profile.save
    elsif plan_id = params[:plan_id]
      @billing_profile.change_plan plan_id
    end

    render nothing: true, status: :accepted
  end
end
