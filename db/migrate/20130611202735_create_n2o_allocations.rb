class CreateN2oAllocations < ActiveRecord::Migration
  def change
    create_table :n2o_allocations do |t|
      t.references :user
      t.integer :amount
      t.integer :kind
      t.string :description
      t.integer :resource_id
      t.string :resource_type
      t.datetime :deallocated_at

      t.timestamps
    end

    add_index :n2o_allocations, :user_id
    add_index :n2o_allocations, :deallocated_at
    add_index :n2o_allocations, [:user_id, :deallocated_at]
  end
end
