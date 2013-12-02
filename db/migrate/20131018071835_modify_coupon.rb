class ModifyCoupon < ActiveRecord::Migration
  def up
    add_column :coupons, :active, :boolean
    add_column :coupons, :duration, :integer
    add_column :coupons, :percent_off, :integer

    remove_column :coupons, :free_trial_length

    add_index :coupons, :code, unique: true
  end

  def down
    remove_column :coupons, :percent_off
    remove_column :coupons, :duration
    remove_column :coupons, :active

    #add_column :coupons, :free_trial_length, :string

    remove_index :coupons, :code
  end
end
