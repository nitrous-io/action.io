class AddReferralCodeToUsers < ActiveRecord::Migration
  def up
    add_column  :users, :referral_code, :string
    User.find_each(batch_size: 1000) { |u| u.set_referral_code! && u.save }
  end

  def down
    remove_column :users, :referral_code
  end
end
