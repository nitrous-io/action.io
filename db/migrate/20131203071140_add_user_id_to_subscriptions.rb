class AddUserIdToSubscriptions < ActiveRecord::Migration
  def up
    add_column :subscriptions, :user_id, :integer
    Subscription.all.each do |subscription|
      if subscription.billing_profile.user_id.present?
        subscription.update_attribute(:user_id, subscription.billing_profile.user_id)
      end
    end
    change_column :subscriptions, :billing_profile_id, :integer, null: true
  end

  def down
    remove_column :subscriptions, :user_id
  end
end
