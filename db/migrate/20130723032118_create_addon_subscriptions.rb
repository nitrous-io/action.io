class CreateAddonSubscriptions < ActiveRecord::Migration
  def change
    create_table :addon_subscriptions do |t|
      t.references  :addon, null: false
      t.references  :box,   null: false
      t.string      :state, null: false, default: 'unsubscribed'
      t.string      :resource_id
      t.text        :encrypted_env_vars
      t.string      :encrypted_env_vars_iv

      t.timestamps
    end

    add_index :addon_subscriptions, :box_id
    add_index :addon_subscriptions, :addon_id
    add_index :addon_subscriptions, [:box_id, :addon_id], unique: true
  end
end
