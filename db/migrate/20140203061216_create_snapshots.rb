class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.belongs_to :box
      t.belongs_to :user
      t.string :name, null: false
      t.string :url
      t.string :state, default: :requested, null: false
      t.boolean :public, default: false, null: false
      t.boolean :manual, default: false, null: false
      t.datetime :completed_at
      t.timestamps
    end

    add_index :snapshots, :box_id
    add_index :snapshots, :user_id
    add_index :snapshots, :state
  end
end
