class RemoveAmiFromRegion < ActiveRecord::Migration
  def up
    remove_column :regions, :ami
  end

  def down
    add_column    :regions, :ami, :string, null: false
  end
end
