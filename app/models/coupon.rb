class Coupon < ActiveRecord::Base
  attr_accessible :code, :duration, :percent_off, :active
  has_many :billing_profiles

  validates_presence_of :code
  validates_numericality_of :percent_off, :duration

  scope :active, where(active: true).order(:id)

  def self.generate(attrs)
    c = new(attrs)
    if c.valid?
      c.send(:create_in_stripe)
    end
    c
  end

  private
  def create_in_stripe
    with_stripe_error_handling do
      Stripe::Coupon.create(
        id: self.code,
        percent_off: self.percent_off,
        duration: 'repeating',
        duration_in_months: self.duration
      )
      self.save
    end
  end

  def with_stripe_error_handling(&block)
    yield
  rescue Stripe::InvalidRequestError => e
    # Invalid parameters were supplied to Stripe's API
    self.errors.add :base, 'Invalid parameters passed to Stripe'
  rescue Stripe::AuthenticationError => e
    # Authentication with Stripe's API failed
    # (maybe you changed API keys recently)
    self.errors.add :base, 'Cannot process your request at this time'
  rescue Stripe::APIConnectionError => e
    # Network communication with Stripe failed
    self.errors.add :base, 'Cannot process your request at this time'
  rescue Stripe::StripeError => e
    self.errors.add :base, 'Cannot process your request at this time'
  end
end
