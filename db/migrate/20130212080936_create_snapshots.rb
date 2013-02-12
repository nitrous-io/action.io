class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string     :name,     null: false
      t.string     :description
      t.boolean    :public
      t.integer    :box_id
      t.integer    :owner_id
      t.timestamps
    end
  end
end
