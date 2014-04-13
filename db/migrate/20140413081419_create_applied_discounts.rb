class CreateAppliedDiscounts < ActiveRecord::Migration
  def change
    create_table :applied_discounts do |t|
      t.integer :percent_off
      t.integer :amount_off
      t.string :stripe_customer_id
      t.timestamp :started_at
      t.timestamp :ended_at
    end

    add_index :applied_discounts, :started_at
    add_index :applied_discounts, :ended_at
  end
end
