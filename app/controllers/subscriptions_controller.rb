class SubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def create
    plan = SubscriptionPlan.find params[:plan_id]
    stripe_token = params[:stripe_token]

    stripe_handler = StripeHandler.new
    customer = stripe_handler.add_customer({ user: current_user, token: stripe_token, plan: plan })

    if customer
      billing_profile = current_user.build_billing_profile
      billing_profile.store_credit_card_attributes customer.id, customer.cards.data.first

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
    stripe_token = params[:stripe_token]
    billing_profile = current_user.billing_profile

    stripe_handler = StripeHandler.new
    customer = stripe_handler.update_customer({ stripe_id: billing_profile.stripe_id, user: current_user, token: stripe_token })

    if customer
      billing_profile.store_credit_card_attributes customer.id, customer.cards.data.first

      if billing_profile.save
        render nothing: true, status: :ok
      else
        render json: { errors: @billing_profile.errors }, status: :unprocessable_entity
      end
    else
      render json: { errors: { base: stripe_handler.error } }, status: :unprocessable_entity
    end
  end

  def update_plan
    plan = SubscriptionPlan.find params[:plan_id]
    billing_profile = current_user.billing_profile
    stripe_handler = StripeHandler.new

    if billing_profile.can_change_to_plan?(plan)
      if stripe_handler.change_plan({ stripe_id: billing_profile.stripe_id, plan: plan })
        render nothing: true, status: :ok
      else
        render json: { errors: { base: stripe_handler.error } }, status: :unprocessable_entity
      end
    else
      render json: { error: { :base, "You need to terminate boxes to free up N2O before downgrading to this plan. Please contact support with any questions" } }, status: :unprocessable_entity
    end
  end

  def destroy
    billing_profile = current_user.billing_profile
    stripe_handler = StripeHandler.new

    if billing_profile.can_cancel_subscription?
      if stripe_handler.cancel_subscription({ stripe_id: billing_profile.stripe_id })
        render nothing: true, status: :ok
      else
        render json: { errors: { base: stripe_handler.error } }, status: :unprocessable_entity
      end
    else
      render json: { error: { :base, "You need to terminate boxes to free up N2O before canceling the current plan. Please contact support with any questions" } }, status: :unprocessable_entity
    end
  end
end
