class AddVersionToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :version, :string
  end
end
