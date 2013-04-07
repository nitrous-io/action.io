class RenameBoxAdminsToBoxUsers < ActiveRecord::Migration
  def change
    rename_table :box_admins, :box_users
  end
end
