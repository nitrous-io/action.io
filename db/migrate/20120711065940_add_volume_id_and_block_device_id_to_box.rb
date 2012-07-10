class AddVolumeIdAndBlockDeviceIdToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :volume_id, :string
    add_column :boxes, :block_device_id, :string
  end
end