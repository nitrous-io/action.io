class RemoveKeypairFromRegion < ActiveRecord::Migration
  def up
    remove_column :regions, :keypair
  end

  def down
    add_column    :regions, :keypair, :text, null: false
  end
end
