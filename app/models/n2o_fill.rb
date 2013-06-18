class N2oFill < ActiveRecord::Base
  N2O_SIGN_UP_BONUS = 'n2o_signup_bonus'.freeze

  belongs_to :user

  module Kind
    FAVOR = 0
    SIGN_UP = 1
  end

  attr_accessible

  after_save do
    user.update_balance!
  end
end
