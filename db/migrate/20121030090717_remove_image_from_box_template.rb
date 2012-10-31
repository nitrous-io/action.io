class RemoveImageFromBoxTemplate < ActiveRecord::Migration
  def up
    remove_column :box_templates, :image
  end

  def down
    add_column :box_templates, :image, :string
  end
end
