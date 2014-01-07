class Coupon < ActiveRecord::Base
  attr_accessible :code, :duration, :percent_off, :active, :description

  validates_presence_of :code
  validates_numericality_of :percent_off, :duration

  scope :active, -> { where(active: true).order(:id) }

  def self.generate(attrs)
    c = new(attrs)
    c.code = c.code.downcase
    if c.valid?
      c.send(:create_in_stripe)
    end
    c
  end

  private

  def create_in_stripe
    begin
      Stripe::Coupon.create(
        id: self.code,
        percent_off: self.percent_off,
        duration: 'repeating',
        duration_in_months: self.duration
      )
      self.save
    rescue Stripe::APIConnectionError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    rescue Stripe::StripeError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    end
  end
end
