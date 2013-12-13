class AddForceShutdownAtToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :force_shutdown_at, :datetime
    add_index :boxes, [:force_shutdown_at, :state]
  end
end
