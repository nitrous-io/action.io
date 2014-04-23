class AddDiscountAndValidTillToRevenueEvent < ActiveRecord::Migration
  def change
    add_column :revenue_events, :discount, :integer
    add_column :revenue_events, :discount_valid_till, :datetime
  end
end
