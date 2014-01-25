class AddMixpanelPropertiesToUserProfile < ActiveRecord::Migration
  def change
    add_column :user_profiles, :mixpanel_properties, :text
  end
end
