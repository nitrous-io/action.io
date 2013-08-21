class Subscriptions::PlansController < ApplicationController
  respond_to :json

  def index
    @plans = SubscriptionPlan.all
    respond_with @plans
  end
end
