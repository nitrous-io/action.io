class DropBoxHosts < ActiveRecord::Migration
  def up
    drop_table  :box_hosts
  end

  def down
    create_table :box_hosts do |t|
      t.references :region, null: false
      t.string     :name,   null: false
      t.string     :host,   null: false
      t.timestamps
    end

    add_index :box_hosts, :region_id
  end
end
