class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :subscription_plan, null: false
      t.references :billing_profile, null: false
      t.references :coupon

      t.string    :state, default: "pending", null: false
      t.timestamps
    end

    add_index :subscriptions, :billing_profile_id
  end
end
