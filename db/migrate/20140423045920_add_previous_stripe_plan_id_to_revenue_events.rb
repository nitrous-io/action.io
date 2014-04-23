class AddPreviousStripePlanIdToRevenueEvents < ActiveRecord::Migration
  def change
    add_column :revenue_events, :previous_stripe_plan_id, :string
    add_index :revenue_events, :previous_stripe_plan_id
  end
end
