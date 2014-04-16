class AddStripeCustomerIdAndPlanIdToRevenueEvents < ActiveRecord::Migration
  def up
    add_column :revenue_events, :stripe_customer_id, :string
    add_column :revenue_events, :stripe_plan_id, :string

    add_index :revenue_events, :stripe_customer_id
    add_index :revenue_events, :stripe_plan_id
  end
end
