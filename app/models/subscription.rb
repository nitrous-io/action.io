class Subscription < ActiveRecord::Base
  attr_accessible :current_price

  belongs_to :billing_profile
  belongs_to :coupon

  state_machine initial: :pending do
    event(:trial)             { transition [:pending]              => :trialing } # are we offering a trial?
    event(:activate)          { transition [:pending, :trialing]   => :active }
    event(:payment_failed)    { transition [:active, :payment_due] => :payment_due }
    event(:cancel)            { transition [:active, :payment_due] => :canceled }

    # on active, fill n2o and send an email on subscription, add mixpanel event
    # on payment failed, send an email, add mixpanel event
    # on cancel, release the n2o, put the boxes in delinquent mode and send an email,
  end
end
