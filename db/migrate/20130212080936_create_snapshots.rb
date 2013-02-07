class CreateSnapshots < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string     :name, null: false
      t.string     :description
      t.string     :url
      t.string     :state, null: false, default: 'new'
      t.boolean    :public, default: false
      t.references :box
      t.references :owner
      t.timestamps
    end
  end
end
