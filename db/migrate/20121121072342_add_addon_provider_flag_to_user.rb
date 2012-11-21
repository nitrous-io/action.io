class AddAddonProviderFlagToUser < ActiveRecord::Migration
  def change
    add_column  :users, :addon_provider, :boolean, default: false
  end
end
