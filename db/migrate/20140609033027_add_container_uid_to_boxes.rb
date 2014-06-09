class AddContainerUidToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :container_uid, :string
    add_index :boxes, :container_uid
  end
end
