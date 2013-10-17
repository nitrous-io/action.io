class AddCpuShareMultiplierAndVirtualMemoryMultiplierToSubscriptionPlan < ActiveRecord::Migration
  def change
    add_column  :subscription_plans, :cpu_shares_multiplier, :integer, default: 1
    add_column  :subscription_plans, :virtual_memory_multiplier, :integer, default: 1
  end
end
