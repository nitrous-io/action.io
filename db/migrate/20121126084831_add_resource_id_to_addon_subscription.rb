class AddResourceIdToAddonSubscription < ActiveRecord::Migration
  def change
    add_column  :addon_subscriptions, :resource_id, :string
  end
end
