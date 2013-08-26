class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.datetime :period_start
      t.datetime :period_end
      t.text     :lines
      t.integer  :subtotal
      t.integer  :total

      t.references :billing_profile, null: false

      t.timestamps
    end

    add_index :receipts, :billing_profile_id
  end
end
