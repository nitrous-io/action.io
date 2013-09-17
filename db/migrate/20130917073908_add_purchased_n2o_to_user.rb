class AddPurchasedN2oToUser < ActiveRecord::Migration
  def change
    add_column :users, :purchased_n2o, :integer
  end
end
