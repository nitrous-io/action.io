class AddReferralAttributesToInvite < ActiveRecord::Migration
  def change
    add_column :invites, :referral_code, :string
    add_column :invites, :referrer_code, :string
    add_column :invites, :referred_visits, :integer, default: 0, null: false

    add_index :invites, :referral_code
    add_index :invites, :referrer_code
  end
end