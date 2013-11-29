class RenameSubscriptionPlanToPlan < ActiveRecord::Migration
  def change
    rename_table :subscription_plans, :plans
    rename_column :subscriptions, :subscription_plan_id, :plan_id
  end
end
