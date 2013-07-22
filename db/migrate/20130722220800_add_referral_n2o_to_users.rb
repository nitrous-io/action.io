class AddReferralN2oToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :referral_n2o, :integer
  end
end
