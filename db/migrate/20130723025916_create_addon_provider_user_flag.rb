class CreateAddonProviderUserFlag < ActiveRecord::Migration
  def change
    add_column :users, :addon_provider, :boolean, default: false
    add_column :users, :addon_provider_has_agreed_terms, :boolean, default: false
  end
end
