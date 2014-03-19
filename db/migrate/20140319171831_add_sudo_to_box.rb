class AddSudoToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :sudo, :boolean, default: false
  end
end
