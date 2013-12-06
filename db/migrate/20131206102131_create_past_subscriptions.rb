class CreatePastSubscriptions < ActiveRecord::Migration
  def change
    create_table :past_subscriptions do |t|
      t.references :user, null: false

      t.string  :plan_name
      t.string  :plan_stripe_id
      t.float   :plan_price
      t.string  :plan_interval
      t.integer :plan_n2o_amount

      t.timestamps
    end
  end
end
