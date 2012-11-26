class AddEncryptedEnvVarsToAddonSubscription < ActiveRecord::Migration
  def change
    add_column  :addon_subscriptions, :encrypted_env_vars, :text
    add_column  :addon_subscriptions, :encrypted_env_vars_iv, :string
  end
end
