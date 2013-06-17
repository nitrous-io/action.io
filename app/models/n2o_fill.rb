class N2oFill < ActiveRecord::Base
  N2O_REFERRAL_SIGNUP_CREDITS = "n2o_referral_signup_credits".freeze

  belongs_to :user

  module Kind
    FAVOR = 0
    SIGN_UP = 1
    REFERRAL = 2
  end

  attr_accessible

  after_save do
    user.update_balance!
  end
end
