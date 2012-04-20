class AddNotNullConstraintsToBoxAdmins < ActiveRecord::Migration
  def up
    change_column :box_admins, :box_id,  :integer, null: false
    change_column :box_admins, :user_id, :integer, null: false
  end

  def down
    change_column :box_admins, :box_id,  :integer
    change_column :box_admins, :user_id, :integer
  end
end
