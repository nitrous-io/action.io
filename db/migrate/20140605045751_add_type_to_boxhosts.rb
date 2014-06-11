class AddTypeToBoxhosts < ActiveRecord::Migration
  def change
    add_column :boxhosts, :type, :string, null: false, default: 'DedicatedBoxhost'
  end
end
