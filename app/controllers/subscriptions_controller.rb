class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    @plan = SubscriptionPlan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    @billing_profile = current_user.create_billing_profile(plan: @plan, stripe_token: stripe_token)
    render nothing: true, status: :accepted
  end
end
