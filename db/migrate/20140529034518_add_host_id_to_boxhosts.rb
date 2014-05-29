class AddHostIdToBoxhosts < ActiveRecord::Migration
  def change
    add_column :boxhosts, :host_id, :string
  end
end
