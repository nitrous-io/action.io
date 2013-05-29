class AddHideTourToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hide_boxes_tour, :boolean
    add_column :users, :hide_ide_tour, :boolean
  end
end
