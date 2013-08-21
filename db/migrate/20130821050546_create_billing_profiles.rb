class CreateBillingProfiles < ActiveRecord::Migration
  def change
    create_table :billing_profiles do |t|
      t.references :user, null: false
      t.string     :stripe_id
      t.string     :last_four
      t.string     :card_type

      t.timestamps
    end
  end
end
