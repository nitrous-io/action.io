class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.string :name,        null: false
      t.string :description, null: false
      t.string :ami,         null: false
      t.text   :keypair,     null: false
      t.timestamps
    end

    add_index :regions, :name, unique: true
  end
end
