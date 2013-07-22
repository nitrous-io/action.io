class RemoveUniquenessIndexOnBoxName < ActiveRecord::Migration
  def up
    remove_index :boxes, column: [:name, :owner_id]
  end

  def down
    add_index :boxes, [:name, :owner_id], unique: true
  end
end
