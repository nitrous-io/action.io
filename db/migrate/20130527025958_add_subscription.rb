class AddSubscription < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.references :plan
      t.references :user
      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :expires_at
      t.timestamps
    end
  end
end
