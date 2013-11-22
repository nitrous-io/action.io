class StripeHandler

  attr_reader :error

  def add_customer(params)
    begin
      token = params.token
      user = params.user
      plan = params.plan

      if token
        Stripe::Customer.create(
          email: user.email,
          description: stripe_description,
          card: self.stripe_token,
          plan: self.plan.stripe_id
        )
      else
        @error = 'Stripe token missing'
        return false
      end
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
    end
  end

  def update_customer(customer, stripe_token)
    if stripe_token.present?
      customer.card = self.stripe_token
    end

    customer.email = self.user.email
    customer.description = stripe_description

    customer.save
  end

  def stripe_description
    "#{user.username} #{user.email}"
  end
end
