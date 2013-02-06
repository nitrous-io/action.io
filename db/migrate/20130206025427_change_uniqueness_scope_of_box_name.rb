class ChangeUniquenessScopeOfBoxName < ActiveRecord::Migration
  def up
    remove_index :boxes, :name
    add_index :boxes, [:name, :owner_id], unique: true
  end

  def down
    add_index :boxes, :name, unique: true
    remove_index :boxes, column: [:name, :owner_id]
  end
end
