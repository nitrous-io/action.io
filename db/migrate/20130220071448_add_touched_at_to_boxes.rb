class AddTouchedAtToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :touched_at, :datetime
  end
end
