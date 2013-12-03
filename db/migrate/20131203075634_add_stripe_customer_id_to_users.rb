class AddStripeCustomerIdToUsers < ActiveRecord::Migration
  def up
    add_column :users, :stripe_customer_id, :string
    BillingProfile.all.each do |billing_profile|
      if user = billing_profile.user
        user.update_attribute(:stripe_customer_id, billing_profile.stripe_id)
      end
    end

    add_index :users, :stripe_customer_id
  end

  def down
    remove_index :users, :stripe_customer_id
    remove_column :users, :stripe_customer_id
  end
end
