class RenameStatusColumnToStateInBoxes < ActiveRecord::Migration
  def change
    rename_column :boxes, :status, :state
  end
end
