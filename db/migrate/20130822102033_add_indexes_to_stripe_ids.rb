class AddIndexesToStripeIds < ActiveRecord::Migration
  def up
    add_index :billing_profiles, :stripe_id, unique: true
    add_index :subscription_plans, :stripe_id, unique: true
  end

  def down
    remove_index :billing_profiles
    remove_index :subscription_plans
  end
end
