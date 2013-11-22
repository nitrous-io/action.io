class StripeHandler

  attr_reader :error

  def add_customer(params)
    with_exception_handling do
      token = params[:token]
      user = params[:user]
      plan = params[:plan]

      if token && plan
        Stripe::Customer.create(
          email: user.email,
          description: "#{user.username} #{user.email}",
          card: token,
          plan: plan.stripe_id
        )
      else
        @error = 'Invalid request (stripe token or plan missing)'
        return false
      end
    end
  end

  def update_customer(params)
    with_exception_handling do
      stripe_id = params[:stripe_id]
      token = params[:token]
      user = params[:user]

      if customer = Stripe::Customer.retrieve(stripe_id)
        if token.present?
          customer.card = token
        end

        customer.email = user.email
        customer.description = "#{user.username} #{user.email}"

        customer.save
        customer
      else
        @error = 'Billing profile not found'
        return false
      end
    end
  end

  def change_plan(params)
    with_exception_handling do
      stripe_id = params[:stripe_id]
      plan = params[:plan]

      if customer = Stripe::Customer.retrieve(stripe_id)
        customer.update_subscription(plan: plan.stripe_id)
      else
        @error = 'Billing profile not found'
        return false
      end
    end
  end

  def cancel_subscription(params)
    with_exception_handling do
      stripe_id = params[:stripe_id]

      if customer = Stripe::Customer.retrieve(stripe_id)
        customer.cancel_subscription
      else
        @error = 'Billing profile not found'
        return false
      end
    end
  end

  private

  def with_exception_handling(&block)
    yield
  rescue Stripe::CardError => e
    body = e.json_body
    err = body[:error]

    if err[:code] == "card_declined"
      error_message = "#{err[:message]} Try contacting your bank directly for assistance."
    else
      error_message = err[:message]
    end

    @error = error_message
    return false
  rescue Stripe::InvalidRequestError => e
    # Invalid parameters were supplied to Stripe's API
    @error = 'Invalid parameters'
    return false
  rescue Stripe::AuthenticationError => e
    # Authentication with Stripe's API failed
    # (maybe you changed API keys recently)
    @error = 'Cannot process your request at this time'
    # send an email to engineering?
    return false
  rescue Stripe::APIConnectionError => e
    # Network communication with Stripe failed
    @error = 'Cannot process your request at this time'
    return false
  rescue Stripe::StripeError => e
    @error = 'Cannot process your request at this time'
    # send an email to engineering?
    return false
  end
end
