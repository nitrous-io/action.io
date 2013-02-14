class AddSnapshot < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :name
      t.string :url
      t.string :status, null: false, default: 'new'
      t.references :box
      t.timestamps
    end
  end
end
