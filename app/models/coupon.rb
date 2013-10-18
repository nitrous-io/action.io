class Coupon < ActiveRecord::Base
  attr_accessible :code, :duration, :percent_off, :active
  has_many :billing_profiles

  validates_presence_of :code
  validates_numericality_of :percent_off, :duration

  scope :active, where(active: true).order(:id)

  before_create :create_in_stripe

  private
  def create_in_stripe
    begin
      Stripe::Coupon.create(
        id: self.code,
        percent_off: self.percent_off,
        duration: 'repeating',
        duration_in_months: self.duration
      )
    rescue => e
      # log rest of the errors for now
      Rails.logger.info e
      return false
    end
  end
end
