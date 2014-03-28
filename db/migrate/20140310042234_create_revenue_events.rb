class CreateRevenueEvents < ActiveRecord::Migration
  def change
    create_table :revenue_events do |t|
      t.integer  :event
      t.integer  :amount
      t.datetime :created_at # use the timestamp in Stripe
      t.datetime :subscription_started_at # applies only to subscription releated events
      t.string   :stripe_id
    end

    add_index :revenue_events, :stripe_id, unique: true
    add_index :revenue_events, :event
    add_index :revenue_events, :created_at
  end
end
