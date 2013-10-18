class AddCouponToBillingProfile < ActiveRecord::Migration
  def change
    add_column :billing_profiles, :coupon_id, :integer
  end
end
