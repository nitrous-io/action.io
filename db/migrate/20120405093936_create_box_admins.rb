class CreateBoxAdmins < ActiveRecord::Migration
  def change
    create_table :box_admins do |t|
      t.references :box
      t.references :user
      t.timestamps
    end

    add_index :box_admins, :box_id
    add_index :box_admins, :user_id
    add_index :box_admins, [:box_id, :user_id], unique: true
  end
end
