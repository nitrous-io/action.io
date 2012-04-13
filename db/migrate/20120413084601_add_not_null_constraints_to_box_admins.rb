class AddNotNullConstraintsToBoxAdmins < ActiveRecord::Migration
  def change
    change_column :box_admins, :box_id,  :integer, null: false
    change_column :box_admins, :user_id, :integer, null: false
  end
end
