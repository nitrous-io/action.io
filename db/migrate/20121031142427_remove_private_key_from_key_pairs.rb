class RemovePrivateKeyFromKeyPairs < ActiveRecord::Migration
  def up
    remove_column :key_pairs, :private_key
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
