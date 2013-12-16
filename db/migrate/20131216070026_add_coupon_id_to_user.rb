class AddCouponIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :coupon_id, :integer
  end
end
