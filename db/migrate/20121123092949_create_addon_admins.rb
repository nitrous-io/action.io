class CreateAddonAdmins < ActiveRecord::Migration
  def change
    create_table :addon_admins do |t|
      t.references  :user
      t.references  :addon

      t.timestamps
    end

    add_index :addon_admins, :addon_id
    add_index :addon_admins, :user_id
    add_index :addon_admins, [:addon_id, :user_id], unique: true
  end
end
