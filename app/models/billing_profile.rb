class BillingProfile < ActiveRecord::Base
  attr_accessible :exp_month, :exp_year, :card_type, :last_four

  belongs_to :user
  has_many :receipts, dependent: :destroy

  scope :with_expiring_cards, ->(expires_at) do
    month = expires_at.month
    year  = expires_at.year

    where(exp_month: month, exp_year: year).
      joins("INNER JOIN users on users.id = billing_profiles.user_id").
      joins("INNER JOIN subscriptions ON subscriptions.user_id = users.id").
      where("subscriptions.state = ?", 'active')
  end

  def expiry
    if exp_month && exp_year
      "#{exp_month}/#{exp_year}"
    end
  end

  def formatted_card_number
    "##############{last_four}"
  end
end
