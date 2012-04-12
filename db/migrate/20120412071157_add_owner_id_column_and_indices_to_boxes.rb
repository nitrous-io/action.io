class AddOwnerIdColumnAndIndicesToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :owner_id, :integer
    add_index :boxes, :owner_id
    add_index :boxes, :name, unique: true
  end
end
