class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token
  belongs_to :user
  before_save :update_stripe

  # must be saved when user model is updated

  attr_accessor :stripe_token

  protected
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def update_stripe
    if stripe_id.nil?
      if !stripe_token.present?
        raise "We're doing something wrong -- this isn't supposed to happen"
      end

      customer = Stripe::Customer.create(
        email: user.email,
        description: stripe_description,
        card: stripe_token
      )
      self.last_four = customer.active_card.last4
      self.card_type = customer.active_card.type
    else
      customer = Stripe::Customer.retrieve(stripe_id)

      if stripe_token.present?
        customer.card = stripe_token
      end

      # in case they've changed
      customer.email = user.email
      customer.description = stripe_description

      customer.save

      self.last_four = customer.active_card.last4
      self.card_type = customer.active_card.type
    end

    self.stripe_id = customer.id
    self.stripe_token = nil
  end
end
