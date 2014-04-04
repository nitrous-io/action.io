require 'bigdecimal'

class Refund < ActiveRecord::Base
  belongs_to :user
  attr_accessible :user_id, :stripe_charge_id, :amount, :reason

  validates_presence_of :amount_in_cents, :stripe_charge_id
  validates_numericality_of :amount_in_cents

  def amount
    self[:amount_in_cents].to_f / 100.0
  end

  def amount=(value)
    self[:amount_in_cents] = (BigDecimal.new(value.to_s) * 100).to_i
  end

  def process!
    if valid? && self.processed_at.nil?
      charge = Stripe::Charge.retrieve self.stripe_charge_id
      charge.refund amount: self.amount_in_cents
      self.processed_at = Time.now
      save!
    end
  rescue ActiveRecord::RecordInvalid  => e
    Airbrake.notify_or_ignore(e) if defined? Airbrake
    Rails.logger.error "Refunded, but failed to save record - #{self.stripe_charge_id}"
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
