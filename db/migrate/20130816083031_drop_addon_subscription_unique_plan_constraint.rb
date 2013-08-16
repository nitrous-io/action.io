class DropAddonSubscriptionUniquePlanConstraint < ActiveRecord::Migration
  def up
    remove_index :addon_subscriptions, [:box_id, :addon_plan_id]
    add_index :addon_subscriptions, [:box_id, :addon_plan_id]
  end

  def down
    remove_index :addon_subscriptions, [:box_id, :addon_plan_id]
    add_index :addon_subscriptions, [:box_id, :addon_plan_id], unique: true
  end
end
