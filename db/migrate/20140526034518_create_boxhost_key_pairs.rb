class CreateBoxhostKeyPairs < ActiveRecord::Migration
  def change
    create_table :boxhost_key_pairs do |t|
      t.references :boxhost
      t.text :public_key, null: false
      t.text :encrypted_private_key, null: false
      t.string :encrypted_private_key_iv, null: false
      t.timestamps
    end

    add_index :boxhost_key_pairs, :boxhost_id
  end
end
