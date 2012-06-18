class AddEnabledToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :enabled, :boolean, default: false, null: false
    add_index  :regions, :enabled
  end
end