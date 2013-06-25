class AddMemoryAndStorageToBoxes < ActiveRecord::Migration
  def up
    add_column :boxes, :memory,  :integer, null: false, default: 384
    add_column :boxes, :storage, :integer, null: false, default: 750

    Box.update_all memory: 384, storage: 1000
  end

  def down
    remove_column :boxes, :memory
    remove_column :boxes, :storage
  end
end
