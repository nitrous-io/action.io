class AddSizeToSnapshots < ActiveRecord::Migration
  def change
    add_column :snapshots, :size, :integer
  end
end
