class AddPendingPlanIdAndInvoiceIdToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :pending_plan_id, :integer
    add_column :subscriptions, :stripe_invoice_id, :string

    add_index :subscriptions, :stripe_invoice_id
  end
end
