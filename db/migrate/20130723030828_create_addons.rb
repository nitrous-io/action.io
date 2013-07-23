class CreateAddons < ActiveRecord::Migration
  def change
    create_table :addons do |t|
      t.string  :uid,                           null: false
      t.text    :config_vars,                   null: false
      t.text    :required_vars
      t.string  :production_base_url,           null: false
      t.string  :production_sso_url,            null: false
      t.string  :test_base_url,                 null: false
      t.string  :test_sso_url,                  null: false
      t.string  :encrypted_password,            null: false
      t.string  :encrypted_password_iv,         null: false
      t.string  :encrypted_sso_salt,            null: false
      t.string  :encrypted_sso_salt_iv,         null: false

      t.string  :state,                         default: 'submitted', null: false
      t.text    :description

      t.integer :owner_id,                      null: false

      t.timestamps
    end

    add_index :addons, :uid
  end
end
