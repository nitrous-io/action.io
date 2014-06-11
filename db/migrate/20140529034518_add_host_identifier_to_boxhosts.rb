class AddHostIdentifierToBoxhosts < ActiveRecord::Migration
  def change
    add_column :boxhosts, :host_identifier, :string
  end
end
