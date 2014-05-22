class AddDedicatedAllowedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :dedicated_allowed, :boolean, default: false
  end
end
