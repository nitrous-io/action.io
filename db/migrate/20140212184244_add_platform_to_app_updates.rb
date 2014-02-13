class AddPlatformToAppUpdates < ActiveRecord::Migration
  def change
    add_column :app_updates, :platform, :string, null: false, default: 'mac'
  end
end
