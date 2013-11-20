class AddCpuMultiplierAndVirtualMemoryToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :cpu_multiplier, :integer, default: 1
    add_column :boxes, :virtual_memory, :integer

    Box.update_all 'virtual_memory = memory'
  end
end
