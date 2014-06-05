class AddBoxhostIdToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :boxhost_id, :integer
    add_index :boxes, :boxhost_id
  end
end
