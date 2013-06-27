class AddProperDatabaseAttributesToN2oAllocationsAndN2oFills < ActiveRecord::Migration
  def change
    change_column :n2o_fills, :user_id, :integer, null: false
    change_column :n2o_fills, :amount,  :integer, null: false, default: 0
    change_column :n2o_fills, :kind,    :integer, null: false

    change_column :n2o_allocations, :user_id, :integer, null: false
    change_column :n2o_allocations, :amount,  :integer, null: false, default: 0
    change_column :n2o_allocations, :kind,    :integer, null: false
  end
end
