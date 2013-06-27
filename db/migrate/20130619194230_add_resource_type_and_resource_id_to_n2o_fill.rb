class AddResourceTypeAndResourceIdToN2oFill < ActiveRecord::Migration
  def change
    add_column  :n2o_fills, :resource_type, :string
    add_column  :n2o_fills, :resource_id,   :integer
  end
end
