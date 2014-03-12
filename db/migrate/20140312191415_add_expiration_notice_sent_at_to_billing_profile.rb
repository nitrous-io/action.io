class AddExpirationNoticeSentAtToBillingProfile < ActiveRecord::Migration
  def change
    add_column :billing_profiles, :expiration_notice_sent_at, :datetime
  end
end
