class AddIndexToReferralCodeOnUsers < ActiveRecord::Migration
  def up
    add_index :users, :referral_code, unique: true
  end

  def down
    remove_index :users, :referral_code
  end
end
