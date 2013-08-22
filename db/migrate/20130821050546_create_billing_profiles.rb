class CreateBillingProfiles < ActiveRecord::Migration
  def change
    create_table :billing_profiles do |t|
      t.references :user, null: false
      t.string     :stripe_id
      t.string     :last_four
      t.string     :card_type
      t.integer    :exp_month
      t.integer    :exp_year

      t.timestamps
    end

    add_index :billing_profiles, :user_id
    add_index :billing_profiles, [:exp_month, :exp_year]
  end
end
