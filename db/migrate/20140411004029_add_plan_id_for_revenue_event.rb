class AddPlanIdForRevenueEvent < ActiveRecord::Migration
  def change
    add_column :revenue_events, :stripe_plan_id, :string
  end
end
