class CreateBoxHosts < ActiveRecord::Migration
  def change
    create_table :box_hosts do |t|
      t.references :region, null: false
      t.string     :name,   null: false
      t.string     :host,   null: false
      t.timestamps
    end

    add_index :box_hosts, :region_id
  end
end
