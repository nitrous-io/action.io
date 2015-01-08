class AddIndexesToN2oFills < ActiveRecord::Migration
  def change
    add_index :n2o_fills, [:resource_id, :resource_type]
  end
end
