class AddPaymentDueToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :payment_due, :boolean, default: false
  end
end
