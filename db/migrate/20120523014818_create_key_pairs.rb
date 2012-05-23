class CreateKeyPairs < ActiveRecord::Migration
  def change
    create_table :key_pairs do |t|
      t.references  :box,         null: false
      t.text        :private_key, null: false
      t.text        :public_key,  null: false
      t.timestamps
    end

    add_index :key_pairs, :box_id
  end
end
