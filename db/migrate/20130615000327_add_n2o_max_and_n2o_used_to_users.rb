class AddN2oMaxAndN2oUsedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :max_n2o,  :integer, null: false, default: 0
    add_column :users, :used_n2o, :integer, null: false, default: 0
  end
end
