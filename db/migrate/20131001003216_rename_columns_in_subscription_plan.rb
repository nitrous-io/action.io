class RenameColumnsInSubscriptionPlan < ActiveRecord::Migration
  def change
    rename_column :subscription_plans, :cpu_shares_multiplier, :cpu_multiplier
    rename_column :subscription_plans, :virtual_memory_multiplier, :vmem_multiplier
  end
end
