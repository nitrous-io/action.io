class BillingProfile < ActiveRecord::Base
  attr_accessible :exp_month, :exp_year, :card_type, :last_four

  belongs_to :user
  has_many :receipts

  def expiry
    if exp_month && exp_year
      "#{exp_month}/#{exp_year}"
    end
  end

  def formatted_card_number
    "##############{last_four}"
  end

  def self.find_profiles_with_expiring_cards(date)
    month = date.try(:month)
    year = date.try(:year)

    if month && year
      self.where(exp_month: month, exp_year: year).all.keep_if do |billing_profile|
        user = billing_profile.user
        user.subscription && user.subscription.active?
      end
    end
  end
end
