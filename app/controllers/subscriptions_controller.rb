class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    plan = SubscriptionPlan.find(params[:plan_id])
    stripe_token = params[:stripe_token]

    stripe_handler = StripeHandler.new
    customer = stripe_handler.add_customer({ user: current_user, token: stripe_token, plan: plan })

    if customer
      billing_profile = current_user.build_billing_profile
      billing_profile.set_card_properties customer.id, customer.cards.data.first

      if billing_profile.persisted?
        render nothing: true, status: :created
      else
        render json: { errors: billing_profile.errors }, status: :unprocessable_entity
      end
    else
      render json: { errors: { base: stripe_handler.error } }, status: :unprocessable_entity
    end
  end

  def update
    @billing_profile = current_user.billing_profile

    @billing_profile.stripe_token = params[:stripe_token]

    unless params[:plan_id].blank?
      @billing_profile.plan = SubscriptionPlan.find(params[:plan_id].to_i)
    end

    if @billing_profile.save
      render nothing: true, status: :ok
    else
      render json: { errors: @billing_profile.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @billing_profile = current_user.billing_profile

    if @billing_profile.cancel_subscription
      render nothing: true, status: :ok
    else
      render json: { errors: @billing_profile.errors }, status: :unprocessable_entity
    end
  end
end
