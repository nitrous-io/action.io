class AddPlan < ActiveRecord::Migration
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active
      t.integer :price_cents
      t.integer :num_boxes
      t.integer :ram
      t.integer :disk_space
      t.boolean :ssh_access
      t.boolean :sleepless
      t.timestamps
    end
  end
end
