class CreateSubscriptionPlans < ActiveRecord::Migration
  def change
    create_table :subscription_plans do |t|
      t.string    :name
      t.string    :stripe_id
      t.float     :price
      t.string    :interval
      t.integer   :n2o_amount

      t.text      :features
      t.boolean   :highlight
      t.integer   :display_order

      t.timestamps
    end
  end
end
