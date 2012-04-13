class CreatePublicKeys < ActiveRecord::Migration
  def change
    create_table :public_keys do |t|
      t.references :user, null: false
      t.string     :name
      t.text       :key,  null: false
      t.timestamps
    end

    add_index :public_keys, :user_id
  end
end
