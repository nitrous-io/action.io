class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    plan = Plan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    if stripe_token.blank?
      render json: { errors: { base: [ 'Invalid request.' ] } }, status: :unprocessable_entity
      return
    end

    if current_user.subscribe plan, stripe_token
      render nothing: true, status: :created
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  def update
    plan = Plan.find(params[:plan_id])

    if current_user.update_subscription(plan)
      render nothing: true, status: :ok
    else
      render json: { errors: current_user.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if current_user.unsubscribe
      render nothing: true, status: :ok
    else
      render json: { errors: billing_profile.errors }, status: :unprocessable_entity
    end
  end
end
