class CreateN2oFills < ActiveRecord::Migration
  def change
    create_table :n2o_fills do |t|
      t.references :user
      t.integer :amount
      t.integer :kind
      t.string :description

      t.timestamps
    end

    add_index :n2o_fills, :user_id
  end
end
