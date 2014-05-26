class MakeKeyPairsPolymorphic < ActiveRecord::Migration
  def change
    rename_column :key_pairs, :box_id, :ssh_identifiable_id
    add_column :key_pairs, :ssh_identifiable_type, :string
    add_index :key_pairs, [:ssh_identifiable_id, :ssh_identifiable_type], name: 'index_key_pairs_on_ssh_identifiable'

    # At this point, all KeyPairs belong to boxes.
    KeyPair.all.each do |key_pair|
      key_pair.update_column :ssh_identifiable_type,  'Box'
    end
  end
end
