class ChangeAddon < ActiveRecord::Migration
  def change
    add_column :addons, :name, :string
    add_column :addons, :icon, :string
    add_column :addons, :tagline, :string

    add_column :addon_subscriptions, :addon_plan_id, :integer
    add_index :addon_subscriptions, :addon_plan_id
    # plan and box has 1-1 relationship for now
    add_index :addon_subscriptions, [:box_id, :addon_plan_id], unique: true
    remove_column :addon_subscriptions, :addon_id
  end
end
