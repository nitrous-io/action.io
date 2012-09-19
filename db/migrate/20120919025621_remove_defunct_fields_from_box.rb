class RemoveDefunctFieldsFromBox < ActiveRecord::Migration
  def up
    remove_column :boxes, :tty_port
    remove_column :boxes, :key
    remove_column :boxes, :volume_id
    remove_column :boxes, :block_device_id
    remove_column :boxes, :ip
  end

  def down
    add_column  :boxes, :tty_port, :integer
    add_column  :boxes, :key, :string, :null => false
    add_column  :boxes, :volume_id, :string
    add_column  :boxes, :block_device_id, :string
    add_column  :boxes, :ip, :string
  end
end
