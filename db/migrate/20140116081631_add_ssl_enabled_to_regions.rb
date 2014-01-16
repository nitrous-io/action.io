class AddSslEnabledToRegions < ActiveRecord::Migration
  def change
    add_column :regions, :ssl_enabled, :boolean, default: false, null: false
  end
end
