class RemoveDedicatedFromBoxhosts < ActiveRecord::Migration
  def change
    remove_column :boxhosts, :dedicated, :boolean, default: true
  end
end
