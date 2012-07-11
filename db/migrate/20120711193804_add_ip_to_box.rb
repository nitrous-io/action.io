class AddIpToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :ip, :string
  end
end